# parse_disk.awk — 从 OpenList /api/admin/storage/list 响应中提取磁盘用量
# 输出: {"updated":<ts>,"storages":[{"name":"...","total":N,"used":N,"free":N},...]}
# 用法: curl ... | awk -v ts="$(date +%s)" -f parse_disk.awk
# 说明: 仅使用 POSIX awk 特性（busybox awk / mawk / gawk 均可运行），
#       不依赖 gawk 独有的 systime()；字段缺失时输出 0 而不是残缺 JSON。

BEGIN { buf = "" }

# 整个响应拼接后再解析，兼容多行 / 带换行的 JSON
{ buf = buf $0 }

END {
  L = length(buf)

  # 收集所有 "mount_path":"..." 的出现位置与名称
  np = 0; p = 0
  while (p < L) {
    i = index(substr(buf, p + 1), "\"mount_path\":\"")
    if (i == 0) break
    st = p + i + 14                     # 跳过 "mount_path":"
    j = index(substr(buf, st), "\"")
    if (j == 0) break
    np++; ppos[np] = p + i; pnames[np] = substr(buf, st, j - 1)
    p = st + j - 1
  }

  # 收集所有 "mount_details":{...} 的出现位置
  nd = 0; p = 0
  while (p < L) {
    i = index(substr(buf, p + 1), "\"mount_details\":{")
    if (i == 0) break
    nd++; dpos[nd] = p + i
    p = p + i + 17
  }

  out = ""
  for (k = 1; k <= nd; k++) {
    # 就近匹配: 取位于该 mount_details 之前最近的 mount_path 作为所属挂载点
    best = 0; bi = 0
    for (t = 1; t <= np; t++)
      if (ppos[t] < dpos[k] && ppos[t] > best) { best = ppos[t]; bi = t }
    if (bi == 0) continue

    det = substr(buf, dpos[k] + 17)     # mount_details 对象内容
    sub(/\}.*/, "", det)

    name = pnames[bi]
    gsub(/\\/, "\\\\", name)            # 转义反斜杠和引号，保证输出是合法 JSON
    gsub(/"/, "\\\"", name)

    out = out (out == "" ? "" : ",\n") \
      "{\"name\":\"" name "\"" \
      ",\"total\":" val(det, "total_space") \
      ",\"used\":" val(det, "used_space") \
      ",\"free\":" val(det, "free_space") "}"
  }

  print "{"
  print "\"updated\":" (ts + 0) ","
  print "\"storages\":["
  if (out != "") print out
  print "]"
  print "}"
}

# 提取对象内的数值字段；键不存在或值非数字时返回 0，避免输出非法 JSON
function val(s, key,  v) {
  v = s
  if (sub(".*\"" key "\":", "", v) == 0) return 0
  sub(/[,}].*/, "", v)
  gsub(/[^0-9]/, "", v)
  return (v == "" ? 0 : v + 0)
}
