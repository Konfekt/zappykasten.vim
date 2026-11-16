#!/bin/sh
# Run the test suite headless in Vim and Neovim.
# Usage: test/run.sh [vim|nvim ...]
set -u
cd "$(dirname "$0")/.." || exit 1
editors=${*:-vim nvim}
status=0
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

for editor in $editors; do
  if ! command -v "$editor" >/dev/null 2>&1; then
    echo "skip: $editor not found"
    continue
  fi
  for file in test/test_*.vim; do
    out="$tmp/$editor-$(basename "$file").txt"
    rm -f "$out"
    case $editor in
      nvim*) "$editor" --headless -u NONE -i NONE -n \
          --cmd "let g:test_file = '$file' | let g:test_out = '$out'" \
          -S test/driver.vim >/dev/null 2>&1 </dev/null ;;
      *) "$editor" -Nu NONE -i NONE -n -es \
          --cmd "let g:test_file = '$file' | let g:test_out = '$out'" \
          -S test/driver.vim >/dev/null 2>&1 </dev/null ;;
    esac
    if [ ! -s "$out" ]; then
      echo "FAIL [$editor] $file: no result written"
      status=1
      continue
    fi
    while IFS= read -r line; do
      echo "[$editor] $(basename "$file") $line"
      case $line in FAIL*) status=1 ;; esac
    done < "$out"
  done
done

if command -v python3 >/dev/null 2>&1; then
  python3 -m unittest discover -s test -p 'test_*.py' -q || status=1
fi
exit $status
