#!/bin/sh
# tests/test_dry_run.sh — `apply --dry-run` and `diff` must make zero
# launchctl calls of any kind, for a YAML mixing new/changed/unchanged/
# orphaned agents, and print the corresponding "Would ..." lines instead.
set -eu

. "$(dirname "$0")/lib/harness.sh"
. "$(dirname "$0")/lib/assert.sh"

fixture="$FIXTURES_DIR/mixed.yaml"

# newone: no prior plist (new-agent path).
# changedone: stale plist on disk, differs from the fixture (changed path).
seed_stale_plist changedone
# unchangedone: plist on disk byte-identical to what render() produces now.
seed_current_plist unchangedone "$fixture"
# orphan: in the manifest, absent from the fixture (prune path).
seed_stale_plist orphan
write_manifest changedone unchangedone orphan

run_launchd_yaml apply --file "$fixture" --dry-run

assert_exit_code 0 "$LAST_EXIT_CODE" "dry-run apply should exit cleanly"
assert_eq "" "$(fake_log)" "dry-run apply must make zero launchctl calls"
assert_contains "$LAST_STDOUT" "Would add: newone" ""
assert_contains "$LAST_STDOUT" "Would reload: changedone" ""
assert_contains "$LAST_STDOUT" "Would prune: orphan" ""

run_launchd_yaml diff --file "$fixture"

assert_exit_code 0 "$LAST_EXIT_CODE" "diff should exit cleanly"
assert_eq "" "$(fake_log)" "diff must make zero launchctl calls"
assert_contains "$LAST_STDOUT" "Would add: newone" ""
assert_contains "$LAST_STDOUT" "Would reload: changedone" ""
assert_contains "$LAST_STDOUT" "Would prune: orphan" ""

echo "dry run ok"
