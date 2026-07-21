#!/bin/sh
# tests/test_harness_sanity.sh — smoke test for the harness itself, not for
# launchd-yaml. Confirms the fake launchctl's print command correctly
# reflects a manually-seeded domain file before any real scenario test
# trusts it.
set -eu

. "$(dirname "$0")/lib/harness.sh"
. "$(dirname "$0")/lib/assert.sh"

target="$(agent_target demo)"

if launchctl print "$target" >/dev/null 2>&1; then
	echo "expected print to fail before the label is seeded" >&2
	exit 1
fi

seed_domain "$target"

if ! launchctl print "$target" >/dev/null 2>&1; then
	echo "expected print to succeed after seeding the domain" >&2
	exit 1
fi

assert_contains "$(fake_log)" "print $target" "invocation log should record the print calls"

echo "harness sanity ok"
