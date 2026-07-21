#!/bin/sh
# tests/test_new_agent.sh — a newly-added agent (no prior plist on disk).
# Covers both sub-cases from spec.md's "New agent loads without unnecessary
# re-bootstrap" scenario, each in its own sandboxed subshell so neither
# leaks fake-domain state into the other.
set -eu

TEST_DIR="$(dirname "$0")"

not_yet_loaded() (
	. "$TEST_DIR/lib/harness.sh"
	. "$TEST_DIR/lib/assert.sh"

	fixture="$FIXTURES_DIR/single-agent.yaml"
	target="$(agent_target demo)"
	export LAUNCHCTL_FAKE_LABEL_FOR_PLIST="$target"

	run_launchd_yaml apply --file "$fixture"

	assert_exit_code 0 "$LAST_EXIT_CODE" "new agent should deploy cleanly"
	assert_contains "$LAST_STDOUT" "1 reloaded" "new agent counts as reloaded"
	if ! domain_contains "$target"; then
		echo "expected $target to be loaded after bootstrap" >&2
		exit 1
	fi
	bootstrap_calls="$(fake_log_count "^bootstrap ")"
	assert_eq 1 "$bootstrap_calls" "bootstrap should fire exactly once"
)

already_loaded() (
	. "$TEST_DIR/lib/harness.sh"
	. "$TEST_DIR/lib/assert.sh"

	fixture="$FIXTURES_DIR/single-agent.yaml"
	target="$(agent_target demo)"
	seed_domain "$target"

	run_launchd_yaml apply --file "$fixture"

	assert_exit_code 0 "$LAST_EXIT_CODE" "new agent should deploy cleanly when already loaded"
	assert_contains "$LAST_STDOUT" "1 reloaded" "new agent still counts as reloaded"
	bootstrap_calls="$(fake_log_count "^bootstrap ")"
	assert_eq 0 "$bootstrap_calls" "bootstrap should be skipped entirely via the fast-path guard"
)

not_yet_loaded
already_loaded

echo "new agent ok"
