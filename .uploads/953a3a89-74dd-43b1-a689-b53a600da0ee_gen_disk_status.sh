#!/bin/sh
# gen_disk_status.sh — 生成磁盘状态数据 /mnt/media/.disk.json，供前端「磁盘状态」卡片读取
# 建议配合 crontab 定时执行，例如: * * * * * /root/gen_disk_status.sh

BASE='http://127.0.0.1:5244'         # OpenList 服务地址
USER='admin'
PASS='A1istJ3160'
OUT='/mnt/media/.disk.json'          # 输出文件（在 OpenList 中挂载为 /NAS）
AWK_SCRIPT='/root/parse_disk.awk'    # 解析脚本部署路径

# 登录获取 token（curl -f: HTTP 异常时以非零码退出，避免拿到错误页继续解析）
TOKEN=$(curl -sf -X POST "$BASE/api/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"$USER\",\"password\":\"$PASS\"}" \
  | sed -n 's/.*"token":"\([^"]*\)".*/\1/p') || exit 1
[ -n "$TOKEN" ] || exit 1

# 拉取存储列表
DATA=$(curl -sf -H "Authorization: $TOKEN" "$BASE/api/admin/storage/list") || exit 1

# 原子写入: 先写临时文件，全部成功后再覆盖，避免页面定时刷新时读到半截 JSON
TMP="$OUT.tmp"
if printf '%s' "$DATA" | awk -v ts="$(date +%s)" -f "$AWK_SCRIPT" > "$TMP" && [ -s "$TMP" ]; then
  mv -f "$TMP" "$OUT"
else
  rm -f "$TMP"
  exit 1
fi
