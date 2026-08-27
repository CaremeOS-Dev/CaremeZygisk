for p in /proc/[0-9]*; do
  pid=${p#/proc/}
  for f in $p/fd/*; do
    t=$(readlink "$f" 2>/dev/null)
    case "$t" in
      *19904*|*19908*|*lspbridge*) echo "pid=$pid $f -> $t" ;;
    esac
  done
done
