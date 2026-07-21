#!/bin/sh
# tests/test_prune.sh — an agent present in the previous manifest but no
# longer in the YAML gets pruned: plist removed, a single bare bootout, no
# wait-for-bootout/bootstrap-confirm machinery, and no effect on `failed`.
set -eu

. "$(dirname "$0")/lib/harness.sh"
. "$(dirname "$0")/lib/assert.sh"

fixture="$FIXTURES_DIR/empty.yaml"
target="$(agent_target demo)"

seed_stale_plist demo
seed_domain "$target"
write_manifest demo

run_launchd_yaml apply --file "$fixture"

assert_exit_code 0 "$LAST_EXIT_CODE" "pruning alone should not fail the run"
assert_contains "$LAST_STDOUT" "1 pruned" "summary should count the prune"
assert_contains "$LAST_STDOUT" "0 failed" "prune should not affect the failed counter"

if [ -f "$LA_DIR/demo.plist" ]; then
	echo "expected demo.plist to be removed" >&2
	exit 1
fi

bootout_calls="$(fake_log_count "^bootout $target$")"
assert_eq 1 "$bootout_calls" "prune should issue exactly one bootout"

print_calls="$(fake_log_count "^print $target$")"
assert_eq 0 "$print_calls" "prune should never poll print"

bootstrap_calls="$(fake_log_count "^bootstrap ")"
assert_eq 0 "$bootstrap_calls" "prune should never attempt a bootstrap"

echo "prune ok"
