#!/bin/sh
BASE=http://127.0.0.1:5244
TOKEN=$(curl -s -X POST $BASE/api/auth/login -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"A1istJ3160\"}" | sed -n "s/.*\"token\":\"\([^\"]*\)\".*/\1/p")
[ -z "$TOKEN" ] && exit 1
DATA=$(curl -s -H "Authorization: $TOKEN" "$BASE/api/admin/storage/list")
echo "$DATA" | awk -f /root/parse_disk.awk > /mnt/media/.disk.json
