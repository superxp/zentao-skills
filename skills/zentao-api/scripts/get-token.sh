#!/usr/bin/env bash
# 获取禅道 API token，按优先级：缓存文件 > 环境变量 token > 账号密码登录。
# 用法：TOKEN=$(bash get-token.sh)
# 依赖：curl, node
# 缓存文件 ~/.zentao-token.json 保存 token、url、account，下次可免密直接使用。
# 注：禅道 token 永久有效；如需切换账号/服务器，删除缓存文件后重新运行即可。

set -euo pipefail

CACHE_FILE="${HOME}/.zentao-token.json"

# ── 1. 优先：从缓存文件读取 url、token、account（单次 node 调用）────────────
if [[ -f "$CACHE_FILE" ]]; then
  mapfile -t _cache < <(node -e "
try {
  const d = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
  process.stdout.write((d.url||'') + '\n' + (d.token||'') + '\n' + (d.account||'') + '\n');
} catch(e) { process.stdout.write('\n\n\n'); }
" "$CACHE_FILE" 2>/dev/null || printf '\n\n\n')
  _cache_url="${_cache[0]:-}"
  _cache_token="${_cache[1]:-}"
  _cache_account="${_cache[2]:-}"

  # 用缓存补全缺失的环境变量
  [[ -z "${ZENTAO_URL:-}"     && -n "$_cache_url"     ]] && ZENTAO_URL="$_cache_url"
  [[ -z "${ZENTAO_ACCOUNT:-}" && -n "$_cache_account" ]] && ZENTAO_ACCOUNT="$_cache_account"

  # 缓存 token 有效且 url/account 均匹配，直接返回（无需密码）
  if [[ -n "$_cache_token" \
     && "${ZENTAO_URL:-}" == "$_cache_url" \
     && ( -z "${ZENTAO_ACCOUNT:-}" || "${ZENTAO_ACCOUNT:-}" == "$_cache_account" ) ]]; then
    echo "$_cache_token"
    exit 0
  fi
fi

# ── 2. 其次：从环境变量读取 token ────────────────────────────────────────────
if [[ -n "${ZENTAO_TOKEN:-}" ]]; then
  echo "$ZENTAO_TOKEN"
  exit 0
fi

# ── 3. 再次：用账号密码重新登录（需 ZENTAO_URL、ZENTAO_ACCOUNT、ZENTAO_PASSWORD）
if [[ -z "${ZENTAO_URL:-}" || -z "${ZENTAO_ACCOUNT:-}" || -z "${ZENTAO_PASSWORD:-}" ]]; then
  echo "错误：Token 获取失败。请通过以下任一方式提供鉴权信息：" >&2
  echo "  · 缓存文件 ~/.zentao-token.json（含 url、token、account 字段）" >&2
  echo "  · 环境变量 ZENTAO_TOKEN（直接提供 token）" >&2
  echo "  · 环境变量 ZENTAO_URL、ZENTAO_ACCOUNT、ZENTAO_PASSWORD（账号密码登录）" >&2
  exit 1
fi

RESPONSE=$(curl -s -X POST "${ZENTAO_URL}/api.php/v2/users/login" \
  -H "Content-Type: application/json" \
  -d "{\"account\": \"${ZENTAO_ACCOUNT}\", \"password\": \"${ZENTAO_PASSWORD}\"}")

TOKEN=$(echo "$RESPONSE" | node -e "
const chunks = [];
process.stdin.on('data', d => chunks.push(d));
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(chunks.join(''));
    const token = (data.data && data.data.token) || data.token || '';
    if (!token) {
      process.stderr.write('登录失败，服务器响应：' + JSON.stringify(data) + '\n');
      process.exit(1);
    }
    process.stdout.write(token);
  } catch (e) {
    process.stderr.write('解析登录响应失败：' + e.message + '\n');
    process.exit(1);
  }
});
") || { echo "错误：登录失败，请查看上方错误信息" >&2; exit 1; }

# ── 4. 缓存：写入 token、url、account ────────────────────────────────────────
node - "$CACHE_FILE" "$TOKEN" "$ZENTAO_URL" "$ZENTAO_ACCOUNT" <<'JSEOF'
const [,, cachePath, token, url, account] = process.argv;
const fs = require('fs');
fs.writeFileSync(cachePath, JSON.stringify({ token, url, account }, null, 2));
JSEOF

echo "$TOKEN"
