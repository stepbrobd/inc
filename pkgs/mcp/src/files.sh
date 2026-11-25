# run by /bin/sh -c on the machine that holds the file, as
#   files.sh size  <path>         print the size of a readable regular file
#   files.sh dest  <path>         check that <path> can be written
#   files.sh read  <path>         print the size line, then exactly that many bytes
#   files.sh write <path> <size>  replace <path> with <size> bytes from stdin
# a relative or ~/ path is taken from $HOME

set -eu

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

p=$2
# shellcheck disable=SC2088 # the caller sends a literal ~/
case $p in
/*) ;;
"~/"*) p=$HOME/${p#"~/"} ;;
*) p=$HOME/$p ;;
esac

size() {
  [ -f "$p" ] || fail "not a regular file: $p"
  [ -r "$p" ] || fail "not readable: $p"
  echo $(($(wc -c <"$p")))
}

dest() {
  d=$(dirname -- "$p")
  [ -d "$d" ] || fail "no such directory: $d"
  [ -w "$d" ] || fail "directory not writable: $d"
  [ ! -d "$p" ] || fail "is a directory: $p"
}

case $1 in
size) size ;;
dest) dest ;;
read)
  n=$(size)
  echo "$n"
  exec head -c "$n" -- "$p"
  ;;
write)
  dest
  t=$(mktemp "$d/.mcp-upload.XXXXXX")
  trap 'rm -f -- "$t"' EXIT
  head -c "$3" >"$t"
  [ $(($(wc -c <"$t"))) -eq "$3" ] || fail "upload ended early"
  if [ -e "$p" ]; then
    m=$(stat -L -c %a -- "$p" 2>/dev/null || stat -L -f %Lp -- "$p")
  else
    m=$(printf %o $((0666 & ~$(umask))))
  fi
  chmod "$m" "$t"
  mv -f -- "$t" "$p"
  trap - EXIT
  ;;
*) fail "unknown verb: $1" ;;
esac
