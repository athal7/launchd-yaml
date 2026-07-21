#!/bin/sh
# tests/test_reload_bootstrap_flaky.sh — the first bootstrap attempt after a
# clean bootout fails to register the label, but a subsequent attempt
# within the retry budget succeeds. apply should recover, not report a
# failure.
set -eu

. "$(dirname "$0")/lib/harness.sh"
. "$(dirname "$0")/lib/assert.sh"

fixture="$FIXTURES_DIR/single-agent.yaml"
target="$(agent_target demo)"

seed_stale_plist demo
seed_domain "$target"

export LAUNCHCTL_FAKE_LABEL_FOR_PLIST="$target"
export LAUNCHCTL_FAKE_BOOTSTRAP_FAILS_UNTIL=1

run_launchd_yaml apply --file "$fixture"

assert_exit_code 0 "$LAST_EXIT_CODE" "apply should succeed once the retry recovers"
assert_contains "$LAST_STDOUT" "0 failed" "summary should report zero failures"
if ! domain_contains "$target"; then
	echo "expected $target to be loaded in the fake domain after recovering" >&2
	exit 1
fi

bootstrap_calls="$(fake_log_count "^bootstrap ")"
assert_eq 2 "$bootstrap_calls" "expected one failed attempt followed by one successful attempt"

echo "reload bootstrap flaky ok"
