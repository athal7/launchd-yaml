#!/bin/sh
# tests/test_self_agent.sh — the --self-agent path never bootouts/reloads
# inline (it hosts the running apply process); it defers to a kickstart
# after the main loop instead. Covers the plain case and the "kickstart
# still runs even though another agent failed" case from spec.md.
set -eu

TEST_DIR="$(dirname "$0")"

self_agent_alone() (
	. "$TEST_DIR/lib/harness.sh"
	. "$TEST_DIR/lib/assert.sh"

	fixture="$FIXTURES_DIR/self-agent.yaml"
	self_target="$(agent_target selfhost)"

	seed_stale_plist selfhost
	seed_domain "$self_target"

	run_launchd_yaml apply --file "$fixture" --self-agent selfhost

	assert_exit_code 0 "$LAST_EXIT_CODE" "a self-agent-only change should succeed"
	assert_contains "$LAST_STDOUT" "1 reloaded" "self-agent change still counts as reloaded"

	bootout_calls="$(fake_log_count "^bootout $self_target$")"
	assert_eq 0 "$bootout_calls" "self-agent must never be booted out inline"

	kickstart_calls="$(fake_log_count "^kickstart -k $self_target$")"
	assert_eq 1 "$kickstart_calls" "self-agent's deferred kickstart should fire exactly once"
)

self_agent_with_failing_peer() (
	. "$TEST_DIR/lib/harness.sh"
	. "$TEST_DIR/lib/assert.sh"

	fixture="$FIXTURES_DIR/self-and-failing.yaml"
	self_target="$(agent_target selfhost)"
	other_target="$(agent_target other)"

	seed_stale_plist selfhost
	seed_stale_plist other
	seed_domain "$self_target"
	seed_domain "$other_target"

	export LAUNCHCTL_FAKE_LABEL_FOR_PLIST="$other_target"
	export LAUNCHCTL_FAKE_BOOTSTRAP_FAILS_UNTIL=10

	run_launchd_yaml apply --file "$fixture" --self-agent selfhost

	assert_exit_code 1 "$LAST_EXIT_CODE" "the other agent's failure should still fail the run"
	assert_contains "$LAST_STDOUT" "1 failed" "summary should report the other agent's failure"

	kickstart_calls="$(fake_log_count "^kickstart -k $self_target$")"
	assert_eq 1 "$kickstart_calls" "self-agent's deferred kickstart must still run despite the other failure"
)

self_agent_alone
self_agent_with_failing_peer

echo "self agent ok"
