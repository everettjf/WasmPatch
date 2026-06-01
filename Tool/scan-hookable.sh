#!/usr/bin/env bash
#
# scan-hookable.sh — list the Objective-C method surface of a Mach-O binary.
#
# WasmPatch can only replace methods that go through Objective-C message
# dispatch. For Objective-C that is every method; for Swift that is ONLY methods
# exposed with `@objc dynamic` (and whose class is an @objc / NSObject subclass).
# Those are exactly the methods that appear in the binary's Objective-C method
# lists, which this script dumps.
#
#   scan-hookable.sh <binary> [ClassNameFilter]
#
# Examples:
#   scan-hookable.sh MyApp.app/Contents/MacOS/MyApp
#   scan-hookable.sh MyApp.app/Contents/MacOS/MyApp ReplaceMe
#
# Note: a method appearing here is necessary but not always sufficient — a Swift
# method must also be `dynamic` to be swizzlable. Treat the list as the
# candidate hook surface and confirm `@objc dynamic` in source.

set -euo pipefail

if [ "${1:-}" = "" ]; then
  echo "usage: $0 <binary> [ClassNameFilter]" >&2
  exit 1
fi

BIN="$1"
FILTER="${2:-}"

if [ ! -f "$BIN" ]; then
  echo "binary not found: $BIN" >&2
  exit 1
fi

command -v otool >/dev/null 2>&1 || { echo "otool is required (install Xcode command line tools)" >&2; exit 1; }

# otool -ov prints each method's "imp" line with the resolved symbol, e.g.
#   imp 0x... (0x...) -[ReplaceMe sumOfRect:]
#   imp 0x... (0x...) +[ReplaceMe classBounds]
# We extract the trailing "[+-]\[Class selector]" token, which is the canonical
# scope/class/selector triple WasmPatch needs.
otool -ov "$BIN" 2>/dev/null \
  | grep -Eo '[-+]\[[A-Za-z_][A-Za-z0-9_]*[^]]*\]' \
  | sort -u \
  | awk -v filter="$FILTER" '
      {
        scope = substr($0, 1, 1)             # + or -
        rest  = substr($0, 3)                # Class selector]
        sub(/\]$/, "", rest)
        sp = index(rest, " ")
        if (sp == 0) { cls = rest; sel = "" } else { cls = substr(rest, 1, sp-1); sel = substr(rest, sp+1) }
        if (filter != "" && cls != filter) next
        key = cls
        if (cls != last) { print ""; print "@ " cls; last = cls }
        printf "    %s[%s %s]\n", scope, cls, sel
      }
  '
