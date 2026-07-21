#!/bin/sh
# tests/test_bootout_absent.sh — bootout on a label already absent from the
# domain should be detected on the first check, not wait out the full
# WFB_ATTEMPTS ceiling before bootstrapping the replacement.
set -eu

. "$(dirname "$0")/lib/harness.sh"
. "$(dirname "$0")/lib/assert.sh"

fixture="$FIXTURES_DIR/single-agent.yaml"
target="$(agent_target demo)"

seed_stale_plist demo
# Deliberately not seeding the domain: the label is already absent when
# bootout runs, matching a previous partial run or a manual bootout.

export LAUNCHCTL_FAKE_LABEL_FOR_PLIST="$target"
export WFB_ATTEMPTS=60

run_launchd_yaml apply --file "$fixture"

assert_exit_code 0 "$LAST_EXIT_CODE" "apply should succeed when the label was already gone"
assert_contains "$LAST_STDOUT" "0 failed" "summary should report zero failures"
if ! domain_contains "$target"; then
	echo "expected $target to be loaded in the fake domain" >&2
	exit 1
fi

# wait_for_bootout should confirm absence on its first poll rather than
# looping WFB_ATTEMPTS times; bootstrap_agent's own confirm-poll adds one
# more. Two print calls total for this label proves no unnecessary looping.
print_calls="$(fake_log_count "^print $target$")"
assert_eq 2 "$print_calls" "expected exactly one wait_for_bootout poll plus one bootstrap confirm poll"

echo "bootout absent ok"
