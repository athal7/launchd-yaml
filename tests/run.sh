#!/bin/sh
# tests/run.sh — discovers and runs test_*.sh under tests/, each in its own
# isolated sandbox (see lib/harness.sh). No bats/shunit2 dependency.
set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

pass=0
fail=0
failed_names=""

for test_file in "$TESTS_DIR"/test_*.sh; do
	[ -f "$test_file" ] || continue
	name="$(basename "$test_file")"
	if output="$(sh "$test_file" 2>&1)"; then
		pass=$((pass + 1))
		echo "ok   $name"
	else
		fail=$((fail + 1))
		failed_names="$failed_names $name"
		echo "FAIL $name"
		echo "$output" | sed 's/^/       /'
	fi
done

total=$((pass + fail))
echo ""
echo "$pass/$total passed"

if [ "$fail" -gt 0 ]; then
	echo "Failed:$failed_names" >&2
	exit 1
fi

exit 0
