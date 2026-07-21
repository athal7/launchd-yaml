#!/bin/sh
# tests/lib/assert.sh — minimal assertion helpers for the plain-sh test
# suite. Each assertion prints a diagnostic to stderr and exits the calling
# test script with status 1 on failure (fail-fast: one bad assertion stops
# the test right there, same as a failed `set -e` command would).
set -eu

assert_eq() {
	expected="$1"
	actual="$2"
	msg="${3:-}"
	if [ "$expected" != "$actual" ]; then
		echo "ASSERT FAILED: ${msg:+$msg: }expected [$expected], got [$actual]" >&2
		exit 1
	fi
}

assert_contains() {
	haystack="$1"
	needle="$2"
	msg="${3:-}"
	case "$haystack" in
	*"$needle"*) ;;
	*)
		echo "ASSERT FAILED: ${msg:+$msg: }expected to find [$needle] in:" >&2
		echo "$haystack" >&2
		exit 1
		;;
	esac
}

assert_not_contains() {
	haystack="$1"
	needle="$2"
	msg="${3:-}"
	case "$haystack" in
	*"$needle"*)
		echo "ASSERT FAILED: ${msg:+$msg: }did not expect to find [$needle] in:" >&2
		echo "$haystack" >&2
		exit 1
		;;
	*) ;;
	esac
}

assert_exit_code() {
	expected="$1"
	actual="$2"
	msg="${3:-}"
	if [ "$expected" != "$actual" ]; then
		echo "ASSERT FAILED: ${msg:+$msg: }expected exit code [$expected], got [$actual]" >&2
		exit 1
	fi
}
