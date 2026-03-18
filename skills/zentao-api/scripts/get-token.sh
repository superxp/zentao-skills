#!/usr/bin/env bash
# 获取禅道 API token，优先使用缓存；切换服务器/账号或手动清除时重新登录。
# 用法：TOKEN=$(bash get-token.sh)
# 依赖：curl, node
# 缓存文件 ~/.zentao-token.json 保存 token、url、account，下次可免填前两项。
# 注：禅道 token 永久有效，仅在 URL/账号变更或用户手动删除缓存时重新登录。

set -euo pipefail

CACHE_FILE="${HOME}/.zentao-token.json"

# 若已设置 ZENTAO_TOKEN，直接使用，跳过缓存和登录流程
if [[ -n "${ZENTAO_TOKEN:-}" ]]; then
  echo "$ZENTAO_TOKEN"
  exit 0
fi

# 从缓存补全缺失的 ZENTAO_URL 和 ZENTAO_ACCOUNT
if [[ -f "$CACHE_FILE" ]]; then
  _cache_url=$(node -e "try{const d=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));process.stdout.write(d.url||'')}catch(e){}" "$CACHE_FILE" 2>/dev/null || true)
  _cache_account=$(node -e "try{const d=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));process.stdout.write(d.account||'')}catch(e){}" "$CACHE_FILE" 2>/dev/null || true)
  [[ -z "${ZENTAO_URL:-}"     && -n "${_cache_url:-}"     ]] && ZENTAO_URL="$_cache_url"
  [[ -z "${ZENTAO_ACCOUNT:-}" && -n "${_cache_account:-}" ]] && ZENTAO_ACCOUNT="$_cache_account"
fi

# 检查必要的环境变量
if [[ -z "${ZENTAO_URL:-}" || -z "${ZENTAO_ACCOUNT:-}" || -z "${ZENTAO_PASSWORD:-}" ]]; then
  echo "错误：请先设置环境变量 ZENTAO_URL、ZENTAO_ACCOUNT、ZENTAO_PASSWORD" >&2
  exit 1
fi

# 尝试从缓存读取 token（校验 URL 和账号均匹配）
if [[ -f "$CACHE_FILE" ]]; then
  CACHED=$(node - "$CACHE_FILE" "$ZENTAO_URL" "$ZENTAO_ACCOUNT" <<'JSEOF'
const [,, cachePath, currentUrl, currentAccount] = process.argv;
try {
  const fs = require('fs');
  const data = JSON.parse(fs.readFileSync(cachePath, 'utf8'));
  if (data.url === currentUrl && data.account === currentAccount && data.token) {
    process.stdout.write(data.token);
  }
} catch (e) {}
JSEOF
  )
  if [[ -n "$CACHED" ]]; then
    echo "$CACHED"
    exit 0
  fi
fi

# 缓存不存在、URL 或账号已变更，重新登录
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

# 写入缓存（保存 token、url、account）
node - "$CACHE_FILE" "$TOKEN" "$ZENTAO_URL" "$ZENTAO_ACCOUNT" <<'JSEOF'
const [,, cachePath, token, url, account] = process.argv;
const fs = require('fs');
fs.writeFileSync(cachePath, JSON.stringify({ token, url, account }));
JSEOF

echo "$TOKEN"
