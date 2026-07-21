#!/bin/sh
# tests/test_reload_bootstrap_fails.sh — bootstrap never registers the
# label within the retry budget. apply must report the failure loudly
# instead of silently counting the agent as reloaded.
set -eu

. "$(dirname "$0")/lib/harness.sh"
. "$(dirname "$0")/lib/assert.sh"

fixture="$FIXTURES_DIR/single-agent.yaml"
target="$(agent_target demo)"

seed_stale_plist demo
seed_domain "$target"

export LAUNCHCTL_FAKE_LABEL_FOR_PLIST="$target"
export LAUNCHCTL_FAKE_BOOTSTRAP_FAILS_UNTIL=10

run_launchd_yaml apply --file "$fixture"

assert_exit_code 1 "$LAST_EXIT_CODE" "apply should exit non-zero when a reload can't be confirmed"
assert_contains "$LAST_STDERR" "ERROR" "stderr should carry an ERROR line"
assert_contains "$LAST_STDERR" "demo" "the error should name the failed agent"
assert_contains "$LAST_STDOUT" "1 failed" "summary should report the failure"

echo "reload bootstrap fails ok"
