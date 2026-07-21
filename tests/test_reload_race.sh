#!/bin/sh
# tests/test_reload_race.sh — a changed agent's bootout lingers past its
# initial call; apply must wait for the domain to actually clear before
# bootstrapping the replacement, instead of racing it.
set -eu

. "$(dirname "$0")/lib/harness.sh"
. "$(dirname "$0")/lib/assert.sh"

fixture="$FIXTURES_DIR/single-agent.yaml"
target="$(agent_target demo)"

seed_stale_plist demo
seed_domain "$target"

export LAUNCHCTL_FAKE_LABEL_FOR_PLIST="$target"
export LAUNCHCTL_FAKE_BOOTOUT_LINGER=3
export WFB_ATTEMPTS=8

run_launchd_yaml apply --file "$fixture"

assert_exit_code 0 "$LAST_EXIT_CODE" "apply should succeed once the lingering bootout clears"
assert_contains "$LAST_STDOUT" "0 failed" "summary should report zero failures"
if ! domain_contains "$target"; then
	echo "expected $target to be loaded in the fake domain after the race resolves" >&2
	exit 1
fi

echo "reload race ok"
