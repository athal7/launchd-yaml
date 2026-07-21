#!/bin/sh
# tests/lib/harness.sh — per-test sandbox. Source (do not execute) from each
# test_*.sh, before lib/assert.sh:
#
#   . "$(dirname "$0")/lib/harness.sh"
#   . "$(dirname "$0")/lib/assert.sh"
#
# Sets up an isolated $HOME/$LA_DIR/$STATE_DIR/$LAUNCHCTL_FAKE_STATE per test
# and puts tests/fakes first on $PATH so tests/fakes/launchctl stands in for
# the real launchctl. See design.md Decision 7.
set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
FIXTURES_DIR="$TESTS_DIR/fixtures"
LAUNCHD_YAML="$REPO_ROOT/launchd-yaml"

SANDBOX="$(mktemp -d)"
harness_cleanup() {
	rm -rf "$SANDBOX"
}
trap harness_cleanup EXIT

export HOME="$SANDBOX/home"
export LA_DIR="$SANDBOX/LaunchAgents"
export STATE_DIR="$SANDBOX/state"
export LAUNCHCTL_FAKE_STATE="$SANDBOX/launchctl-state"
mkdir -p "$HOME" "$LA_DIR" "$STATE_DIR" "$LAUNCHCTL_FAKE_STATE"

DOMAIN_FILE="$LAUNCHCTL_FAKE_STATE/domain"
LOG_FILE="$LAUNCHCTL_FAKE_STATE/log"
: >"$DOMAIN_FILE"
: >"$LOG_FILE"

PATH="$TESTS_DIR/fakes:$PATH"
export PATH

TEST_USER="$(id -un)"
TEST_UID="$(id -u)"

# Full "gui/<uid>/com.<user>.<name>" service target for an agent name,
# matching the construction launchd-yaml itself uses for $label.
agent_target() {
	printf 'gui/%s/com.%s.%s\n' "$TEST_UID" "$TEST_USER" "$1"
}

# Mark a label as already loaded in the fake domain, bypassing launchctl —
# for seeding "already running" preconditions.
seed_domain() {
	printf '%s\n' "$1" >>"$DOMAIN_FILE"
}

domain_contains() {
	grep -qxF "$1" "$DOMAIN_FILE" 2>/dev/null
}

fake_log() {
	cat "$LOG_FILE"
}

fake_log_count() {
	grep -c "$1" "$LOG_FILE" 2>/dev/null || true
}

# Write a plist to $LA_DIR/<name>.plist with arbitrary placeholder bytes, to
# force launchd-yaml's content-diff check to treat the agent as "changed"
# regardless of what the YAML fixture actually renders to.
seed_stale_plist() {
	name="$1"
	mkdir -p "$LA_DIR"
	printf '<!-- stale placeholder, forces a content diff -->\n' >"$LA_DIR/$name.plist"
}

# Replicate launchd-yaml's render() exactly, so a test can seed an
# "unchanged" plist (byte-identical to what the real render would produce)
# without invoking the production script to generate it.
render_agent_plist() {
	yaml="$1"
	name="$2"
	yq -o=json ".launchagents.\"$name\"" "$yaml" \
		| plutil -convert xml1 -o - - \
		| sed -e "s#\$HOME#$HOME#g" -e "s#\$USER#$TEST_USER#g"
	printf '\n'
}

seed_current_plist() {
	name="$1"
	yaml="$2"
	mkdir -p "$LA_DIR"
	render_agent_plist "$yaml" "$name" >"$LA_DIR/$name.plist"
}

write_manifest() {
	mkdir -p "$STATE_DIR"
	printf '%s\n' "$@" >"$STATE_DIR/managed.list"
}

# Runs launchd-yaml, capturing stdout/stderr/exit code for the caller to
# assert against via $LAST_STDOUT / $LAST_STDERR / $LAST_EXIT_CODE.
#
# --dest/--state are forced to the sandbox here because launchd-yaml
# unconditionally assigns LA_DIR/STATE_DIR from $HOME at the top of the
# script (not `${LA_DIR:=...}`), so exporting those env vars alone would be
# silently overwritten — the flags are the only real override seam.
run_launchd_yaml() {
	set +e
	"$LAUNCHD_YAML" --dest "$LA_DIR" --state "$STATE_DIR" "$@" >"$SANDBOX/stdout" 2>"$SANDBOX/stderr"
	LAST_EXIT_CODE=$?
	set -e
	LAST_STDOUT="$(cat "$SANDBOX/stdout")"
	LAST_STDERR="$(cat "$SANDBOX/stderr")"
}
