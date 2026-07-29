#!/bin/sh
# tests/test_failed_bootout.sh — test cases where launchctl bootout or kickstart fails.
# Asserts that stderr is captured, printed, and causes a non-zero exit code.
set -eu

TEST_DIR="$(dirname "$0")"

test_reload_bootout_fails() (
	. "$TEST_DIR/lib/harness.sh"
	. "$TEST_DIR/lib/assert.sh"

	fixture="$FIXTURES_DIR/single-agent.yaml"
	target="$(agent_target demo)"

	seed_stale_plist demo
	seed_domain "$target"

	export LAUNCHCTL_FAKE_LABEL_FOR_PLIST="$target"
	export LAUNCHCTL_FAKE_BOOTOUT_FAILS=1

	run_launchd_yaml apply --file "$fixture"

	assert_exit_code 1 "$LAST_EXIT_CODE" "apply should fail when reload bootout fails"
	assert_contains "$LAST_STDERR" "ERROR: Failed to bootout demo" "stderr should report bootout failure"
	assert_contains "$LAST_STDERR" "launchctl bootout: mock failure error" "stderr should contain captured bootout error"
	assert_contains "$LAST_STDOUT" "1 failed" "summary should report failure"
)

test_prune_bootout_fails() (
	. "$TEST_DIR/lib/harness.sh"
	. "$TEST_DIR/lib/assert.sh"

	fixture="$FIXTURES_DIR/empty.yaml"
	target="$(agent_target demo)"

	seed_stale_plist demo
	seed_domain "$target"
	write_manifest demo

	export LAUNCHCTL_FAKE_BOOTOUT_FAILS=1

	run_launchd_yaml apply --file "$fixture"

	assert_exit_code 1 "$LAST_EXIT_CODE" "apply should fail when prune bootout fails"
	assert_contains "$LAST_STDERR" "ERROR: Failed to bootout pruned agent demo" "stderr should report prune bootout failure"
	assert_contains "$LAST_STDERR" "launchctl bootout: mock failure error" "stderr should contain captured bootout error"
	assert_contains "$LAST_STDOUT" "1 failed" "summary should report failure"
)

test_kickstart_fails() (
	. "$TEST_DIR/lib/harness.sh"
	. "$TEST_DIR/lib/assert.sh"

	fixture="$FIXTURES_DIR/self-agent.yaml"
	self_target="$(agent_target selfhost)"

	seed_stale_plist selfhost
	seed_domain "$self_target"

	export LAUNCHCTL_FAKE_KICKSTART_FAILS=1

	run_launchd_yaml apply --file "$fixture" --self-agent selfhost

	assert_exit_code 1 "$LAST_EXIT_CODE" "apply should fail when kickstart fails"
	assert_contains "$LAST_STDERR" "ERROR: Failed to kickstart self-agent selfhost" "stderr should report kickstart failure"
	assert_contains "$LAST_STDERR" "launchctl kickstart: mock failure error" "stderr should contain captured kickstart error"
)

test_reload_bootout_fails
test_prune_bootout_fails
test_kickstart_fails

echo "failed bootout and kickstart tests ok"
