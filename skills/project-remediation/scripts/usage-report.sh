#!/usr/bin/env bash
#
# usage-report.sh — best-effort usage/quota reporter for the project-remediation
# skill.
#
# Prints a short summary of the current usage window (how much has been consumed
# and, where the tool exposes it, when it resets) so the orchestrating agent can
# decide whether there is headroom to launch the next subagent. See
# references/quota-and-pacing.md.
#
# Contract: this script is designed to run as a PreToolUse hook, so it MUST NOT
# fail a tool call. It always exits 0, and it prints a clear note when no usage
# information is available rather than erroring. It reads only; it changes
# nothing and needs no arguments.
#
# It reports whatever local usage tooling is installed. `ccusage`
# (https://github.com/ryoppippi/ccusage) is a widely used community CLI that
# estimates usage from Claude Code's local session logs; if it is present (or
# runnable via npx) this script surfaces its active-block view. If no such tool
# is found, the skill falls back to reactive limit-handling, which needs no tool.

set -u

emit() { printf '%s\n' "$*"; }

emit "== project-remediation usage report =="
emit "time: $(date -Is 2>/dev/null || date)"

reported=0

# Prefer an installed `ccusage`; otherwise try a cached npx copy without
# triggering a network install (that would be slow and could prompt).
run_ccusage() {
  if command -v ccusage >/dev/null 2>&1; then
    ccusage "$@" 2>/dev/null
    return $?
  fi
  if command -v npx >/dev/null 2>&1; then
    npx --no-install ccusage "$@" 2>/dev/null
    return $?
  fi
  return 127
}

if out=$(run_ccusage blocks --active 2>/dev/null) && [ -n "$out" ]; then
  emit "source: ccusage (active block)"
  emit "$out"
  reported=1
elif out=$(run_ccusage blocks 2>/dev/null) && [ -n "$out" ]; then
  emit "source: ccusage (recent blocks)"
  emit "$out"
  reported=1
fi

if [ "$reported" -eq 0 ]; then
  emit "source: none"
  emit "No local usage tool found (looked for 'ccusage', and 'npx --no-install ccusage')."
  emit "The skill will rely on reactive limit-handling: capture the reset time from"
  emit "any usage-limit message when it occurs, then pause or stop per the six-hour rule."
fi

exit 0
