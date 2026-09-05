BEGIN {
  print "{"
  print "\"updated\":" systime() ","
  print "\"storages\":["
  first=1
}
{
  s=$0; L=length(s)
  np=0; p=0
  while (p < L) {
    i=index(substr(s,p+1), "\"mount_path\":\"")
    if (i==0) break
    st=p+i+15
    j=index(substr(s,st), "\"")
    np++; ppos[np]=p+i; pnames[np]=substr(s,st,j-1)
    p=st+j-1
  }
  nd=0; p=0
  while (p < L) {
    i=index(substr(s,p+1), "\"mount_details\":{")
    if (i==0) break
    nd++; dpos[nd]=p+i
    p=p+i+18
  }
  for (k=1;k<=nd;k++) {
    best=0; bi=0
    for (t=1;t<=np;t++) if (ppos[t]<dpos[k] && ppos[t]>best) { best=ppos[t]; bi=t }
    det=substr(s,dpos[k]+18)
    sub(/\}.*/, "", det)
    tot=det; sub(/.*"total_space":/, "", tot); sub(/,.*/, "", tot)
    usd=det; sub(/.*"used_space":/, "", usd); sub(/,.*/, "", usd)
    fre=det; sub(/.*"free_space":/, "", fre); sub(/,.*/, "", fre)
    gsub(/[^0-9]/, "", tot); gsub(/[^0-9]/, "", usd); gsub(/[^0-9]/, "", fre)
    if (!first) printf ",\n"
    printf "{\"name\":\"%s\",\"total\":%s,\"used\":%s,\"free\":%s}", pnames[bi], tot, usd, fre
    first=0
  }
}
END {
  print ""
  print "]"
  print "}"
}
