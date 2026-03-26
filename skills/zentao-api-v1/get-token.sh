#!/bin/bash
# 禅道 API v1.0 - 获取 Token 脚本
# 用法: ./get-token.sh <zentao_url> <username> <password>

set -e

ZENTAO_URL="${1:-http://localhost}"
USERNAME="${2:-admin}"
PASSWORD="${3:-Admin1234}"

# 缓存文件路径
CACHE_DIR="${HOME}/.zentao"
CACHE_FILE="${CACHE_DIR}/token_cache.json"

# 确保缓存目录存在
mkdir -p "${CACHE_DIR}"

# 检查缓存是否有效（1小时内）
if [ -f "${CACHE_FILE}" ]; then
  CACHED_URL=$(cat "${CACHE_FILE}" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
  CACHED_TOKEN=$(cat "${CACHE_FILE}" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
  CACHED_TIME=$(cat "${CACHE_FILE}" | grep -o '"time":[0-9]*' | cut -d':' -f2)
  CURRENT_TIME=$(date +%s)

  if [ "${CACHED_URL}" = "${ZENTAO_URL}" ] && [ -n "${CACHED_TOKEN}" ]; then
    TIME_DIFF=$((CURRENT_TIME - CACHED_TIME))
    if [ ${TIME_DIFF} -lt 3600 ]; then
      echo "${CACHED_TOKEN}"
      exit 0
    fi
  fi
fi

# 获取新 Token
RESPONSE=$(curl -s -X POST \
  "${ZENTAO_URL}/api.php/v1/tokens" \
  -H "Content-Type: application/json" \
  -d "{\"account\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}")

TOKEN=$(echo "${RESPONSE}" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "${TOKEN}" ]; then
  echo "Error: Failed to get token. Response: ${RESPONSE}" >&2
  exit 1
fi

# 保存到缓存
CURRENT_TIME=$(date +%s)
echo "{\"url\":\"${ZENTAO_URL}\",\"token\":\"${TOKEN}\",\"time\":${CURRENT_TIME}}" > "${CACHE_FILE}"
chmod 600 "${CACHE_FILE}"

echo "${TOKEN}"
