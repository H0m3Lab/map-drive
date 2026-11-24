#!/bin/bash
# Unit tests for map-drive's pure helpers (no mounting, no sudo). Run: bash tests/test.sh
set -u
cd "$(dirname "$0")/.." || exit 1
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME="$T/home" MAP_DRIVE_CONF="$T/none.conf"
export MAP_DRIVE_PLACES="$T/home/.local/share/user-places.xbel" MAP_DRIVE_GTK="$T/home/.config/gtk-3.0/bookmarks"
# shellcheck source=../map-drive
. ./map-drive

fail=0
check() {  # check <name> <expected> <actual>
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: expected [$2] got [$3]"; fail=1; fi
}

check "letter Z"           "z" "$(norm_letter Z)"
check "letter y:"          "y" "$(norm_letter 'y:')"
check "letter bad"         ""  "$(norm_letter ZZ)"
check "letter digit"       ""  "$(norm_letter 1)"
check "unc backslashes"    "//nas/MyFiles"     "$(norm_share '\\nas\MyFiles')"
check "unc slashes"        "//nas/MyFiles"     "$(norm_share '//nas/MyFiles/')"
check "unc subfolder"      "//nas/Share/Sub"   "$(norm_share '\\nas\Share\Sub')"
check "unc no share"       ""                  "$(norm_share '\\nas')"
check "unc no slashes"     ""                  "$(norm_share 'nas/share')"
check "unc space in host"  ""                  "$(norm_share '//my nas/share')"
check "unc display"        '\\nas\MyFiles'     "$(unc //nas/MyFiles)"

places_add z "Z (MyFiles)"
places_add z "Z (MyFiles)"   # second call must not duplicate
check "kde entry once"     "1" "$(grep -c 'href="file:///mnt/z"' "$MAP_DRIVE_PLACES")"
check "gtk entry once"     "1" "$(grep -c '^file:///mnt/z ' "$MAP_DRIVE_GTK")"
check "gtk title"          "file:///mnt/z Z (MyFiles)" "$(cat "$MAP_DRIVE_GTK")"
python3 -c 'import sys,xml.dom.minidom; xml.dom.minidom.parse(sys.argv[1])' "$MAP_DRIVE_PLACES" \
  && echo "ok   kde file is valid XML" || { echo "FAIL kde file is not valid XML"; fail=1; }

places_add y "Y (A&B <x>)"
python3 -c 'import sys,xml.dom.minidom; xml.dom.minidom.parse(sys.argv[1])' "$MAP_DRIVE_PLACES" \
  && echo "ok   title with & and < is escaped" || { echo "FAIL title escaping"; fail=1; }

places_remove z
check "kde entry removed"  "0" "$(grep -c 'href="file:///mnt/z"' "$MAP_DRIVE_PLACES")"
check "gtk entry removed"  "0" "$(grep -c '^file:///mnt/z ' "$MAP_DRIVE_GTK")"
check "other entry kept"   "1" "$(grep -c 'href="file:///mnt/y"' "$MAP_DRIVE_PLACES")"
python3 -c 'import sys,xml.dom.minidom; xml.dom.minidom.parse(sys.argv[1])' "$MAP_DRIVE_PLACES" \
  && echo "ok   kde file still valid after remove" || { echo "FAIL kde file broken after remove"; fail=1; }

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo "ok   version $VERSION" || { echo "FAIL version [$VERSION]"; fail=1; }

[ $fail = 0 ] && echo "All tests passed." || { echo "Some tests FAILED."; exit 1; }
