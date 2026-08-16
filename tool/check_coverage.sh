#!/usr/bin/env bash
#
# Reports line coverage for lib/. Informational only: this script does not fail
# the build, by project decision. Set COVERAGE_THRESHOLD to a number to turn it
# back into a gate (it will then exit non-zero below that percentage).
#
# Generated files are always excluded: AutoRoute's router (*.gr.dart) and the
# FlutterFire CLI's firebase_options.dart.
#
# Usage:
#   flutter test --coverage && ./tool/check_coverage.sh

set -euo pipefail

THRESHOLD="${COVERAGE_THRESHOLD:-}"
LCOV="coverage/lcov.info"
FILTERED="coverage/lcov.filtered.info"

if [[ ! -f "$LCOV" ]]; then
  echo "error: $LCOV not found. Run 'flutter test --coverage' first." >&2
  exit 1
fi

# Drop generated records. Written in awk rather than lcov(1) so the report has
# no dependency beyond what the Flutter toolchain already provides.
awk '
  /^SF:/ { keep = ($0 !~ /\.gr\.dart$/ && $0 !~ /firebase_options\.dart$/) }
  keep   { print }
' "$LCOV" > "$FILTERED"

awk -v threshold="$THRESHOLD" -v SORT='sort -k2' '
  /^SF:/ { file = substr($0, 4); files[file] = 1 }
  /^DA:/ {
           split(substr($0, 4), a, ",")
           total++; fileTotal[file]++
           if (a[2] + 0 > 0) { hit++; fileHit[file]++ }
           else uncovered[file] = uncovered[file] "    " file ":" a[1] "\n"
         }
  END {
    if (total == 0) {
      print "error: no coverage records found after filtering." > "/dev/stderr"
      exit 1
    }

    # Piped through sort(1) because BSD awk has no asorti().
    for (f in files) {
      printf "%6.1f%%  %s\n", fileHit[f] * 100 / fileTotal[f], f | SORT
    }
    close(SORT)

    pct = hit * 100 / total
    printf "\nTotal: %d/%d lines (%.2f%%)\n", hit, total, pct

    if (length(uncovered) > 0) {
      print "\nUncovered lines:"
      for (f in uncovered) printf "%s", uncovered[f]
    }

    if (threshold != "") {
      if (pct + 0 < threshold + 0) {
        printf "\nFAIL: coverage %.2f%% is below the %s%% threshold.\n", pct, threshold > "/dev/stderr"
        exit 1
      }
      printf "\nPASS: at or above the %s%% threshold.\n", threshold
    }
  }
' "$FILTERED"
