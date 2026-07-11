# Quota awareness and pacing

A remediation campaign can dispatch many subagents and run for hours, so it is the kind of work that hits a usage limit mid-flight. Hitting one is not catastrophic — the checkpoint discipline means a limit costs at most the unit in flight — but handling it deliberately is far better than failing blindly: the skill should notice quota running low, **pause until it resets** when the wait is short, and **stop cleanly** when the wait is long, in both cases leaving a resumable state file.

## The rule

Before launching each subagent (and whenever a limit is actually hit):

1. **If quota is comfortable**, proceed.
2. **If a limit is hit, or is judged imminent, and the reset is within six hours**, pause until the reset, then continue the campaign. Record the pause in the state file's `quota` block first, so an interruption during the wait still resumes correctly.
3. **If the wait to reset would exceed six hours** — or quota is exhausted with no discoverable reset time — **stop**. Checkpoint, set the `quota.note`, and tell the user the reset time (if known) and that re-invoking the skill will resume automatically. Do not sleep for more than six hours inside a single run.

Six hours is the boundary between "wait it out" and "hand back to the user": a short pause keeps the campaign coherent in one session, while a long one is better served by the resume machinery, which survives the machine being turned off.

## Knowing where quota stands

There is no single portable API for "quota remaining", so use the best signal your environment offers, in this order:

1. **A usage-reporting hook or command** (see below), if configured — the proactive signal. It reports the active usage window, how much is consumed, and when it resets, letting you decide *before* launching whether there is headroom for the next unit.
2. **The last observed reset time**, captured from any limit message seen earlier in the session and stored in `quota.reset_at`. Usage-limit responses state when access returns; capture that timestamp the moment you see it.
3. **Reactive handling** when a subagent aborts because a limit was reached: read the reset time from the failure, record it, and apply the rule above. The aborted unit stays `in-progress` (or is reset to `pending`) and is retried after the pause or on the next invocation — it is never marked resolved.

## Estimating whether the next unit fits

Prediction is inherently rough; keep it simple and lean toward pausing early rather than failing late. Use the unit's **effort** as a proxy for cost — a Small mechanical unit on a low tier is cheap; a Large unit on a high-capability tier, which may itself spawn subagents, is expensive — and compare it against whatever headroom the usage report shows. If the report shows the active window nearly consumed and the next unit is large, treat quota as "imminent" under the rule above and pause rather than starting work you cannot finish. If you have no usage data at all, proceed but be ready to handle a mid-flight limit reactively; the checkpoint after the previous unit means nothing already-verified is lost.

## How to "pause"

Wait by whatever mechanism your environment provides that does **not** itself consume quota or busy-loop:

- A scheduled wake-up or a background timer that re-invokes the session when the reset passes is ideal — the skill resumes and continues.
- If the environment offers no way to sleep without spending quota (some do block a foreground sleep), treat the pause as a **stop**: checkpoint, tell the user the reset time, and end the run. Re-invoking after the reset resumes from the state file — functionally identical to having slept. This is also exactly what the six-hour rule requires for long waits, so the two paths converge.

Never spin in a tight loop or keep issuing calls to "check" quota — that spends the very budget you are trying to preserve.

## Optional: a usage-reporting hook

To make the proactive signal available, the environment can run a small command that prints current usage before each subagent launch, so its output lands in the transcript for the orchestrator (and the user) to read. This is **optional** — the skill degrades to the reactive path without it — and, because installing it edits `settings.json`, it is the user's choice to add. Offer it in Step 0; do not install it silently.

`scripts/usage-report.sh` (shipped with this skill) is a best-effort reporter: it prints the active usage window from a local usage tool if one is installed, and otherwise prints a clear "no usage tool available" note and exits 0 so it can never break a tool call. A `PreToolUse` hook matching the subagent-launch tool surfaces it at exactly the right moments:

```jsonc
// .claude/settings.json (or via the update-config skill)
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Task|Agent",
        "hooks": [
          { "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/skills/project-remediation/scripts/usage-report.sh" }
        ]
      }
    ]
  }
}
```

Adjust the path to wherever the skill is installed (a personal skill lives under `~/.claude/skills/`; the hook command must point at the real location). Removing the hook after the campaign keeps it from firing on unrelated work. If the environment exposes usage some other way — a status line, a dedicated command — prefer reading that and skip the hook entirely.
