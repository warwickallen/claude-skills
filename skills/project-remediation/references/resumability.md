# Resumability

A remediation campaign implements many items across many subagents; it can easily run for hours and is a prime candidate for interruption — quota exhaustion, a dropped network, a power cut, or a deliberate stop when a quota reset is more than six hours away. Progress must therefore never live only in memory: it is checkpointed to disk after every unit, and a fresh session resumes from the last checkpoint automatically, losing at most the one unit in flight.

## Two records, one folder

This skill keeps **two** files, deliberately split by purpose:

- **`remediation-state.json`** — the machine-readable resume ledger. It holds the merged backlog, each unit's status, quota timing, and the run's settings. It exists only while the campaign is unfinished; its **absence is the signal that the campaign completed**, exactly as `project-review` treats its own state file.
- **`05-implementation-log.md`** (in a review folder) or **`implementation-log.md`** (tech-debt-only mode) — the durable, human-readable record of what was done. It is the *product*: it survives completion, is safe to commit, and answers "what has been implemented?" long after the state file is gone.

They are split because they serve different readers: the JSON is for the next session's automatic resumption; the Markdown is for a human reviewing outcomes. Keeping the log free of machine bookkeeping keeps it readable; keeping the state file separate lets it be deleted on completion without losing the record.

Both live in the same folder:

```
reviews/project-review-YYYY-MM-DD/     (or  remediation/remediation-YYYY-MM-DD/  in tech-debt-only mode)
├── 03-recommendations.md          # input (from project-review)
├── 04-improvement-prompts.md      # input (from project-review)
├── 05-implementation-log.md       # durable output — the product
└── remediation-state.json         # transient resume ledger — deleted on completion
```

## `remediation-state.json` schema

Write it atomically — write to a temporary file and rename — so an interruption cannot leave it half-written.

```json
{
  "skill": "project-remediation",
  "status": "in-progress",
  "project_root": "<absolute path>",
  "revision": "<commit hash at last checkpoint>",
  "review_folder": "<path, or null in tech-debt-only mode>",
  "tech_debt_file": "<path to the register, or null>",
  "tech_debt_helper": "<how tech-debt items are worked: '/td skill', 'scripts/get-tech-debt-record.pl', or null>",
  "commit_policy": "working-tree",
  "started": "<ISO 8601>",
  "updated": "<ISO 8601 — refresh at every checkpoint>",
  "quota": {
    "reset_at": "<ISO 8601 of the next known quota reset, or null>",
    "last_report": "<ISO 8601 when usage was last observed, or null>",
    "note": "<free text, e.g. 'limit hit dispatching U-04; paused until reset'>"
  },
  "units": [
    {
      "id": "U-01",
      "title": "<short title>",
      "recommendation_ids": ["R-09"],
      "tech_debt_ids": ["TD26071107"],
      "finding_ids": ["F-CODE-02", "F-ARCH-03"],
      "severity": "Low",
      "effort": "Small",
      "run_after": [],
      "tier": "<low | mid | high, once chosen>",
      "status": "pending",
      "evidence": "<commit hashes / paths proving the outcome, once known>",
      "notes": "<verification result, deferral/block reason, suggested commit message>"
    }
  ]
}
```

Unit `status` values: `pending` (reconciled as still open), `already-resolved` (found done during reconciliation), `in-progress` (a subagent is working it), `resolved` (implemented and verified), `deferred` (consciously postponed, with reason), `blocked` (cannot proceed, with reason). Top-level `status` is `in-progress` until every unit is terminal, then the state file is deleted rather than set to `complete`.

`commit_policy` is `working-tree` by default (leave changes uncommitted, record a suggested message per unit) or `per-item` only if the user asked for commits — see `subagent-dispatch.md`.

## Checkpoint discipline

Checkpoint by writing the log *first*, then updating `remediation-state.json`, at each of these moments:

1. End of Step 0 — create the folder, log header, and initial state file.
2. End of Step 1 — write the built backlog to both files.
3. End of Step 2 — record every unit's reconciled status (`pending` or `already-resolved`).
4. End of *each unit* in Step 3 — never batch. The whole point is that an interruption loses at most the unit in flight.
5. Whenever quota timing changes (a limit hit, a reset observed, a pause begun) — update the `quota` block immediately, so a resumed session knows whether it may proceed.
6. Completion — delete `remediation-state.json`; the finished log is the record.

## Resuming

At the very start of Step 0, before anything else, look for a `remediation-state.json` with status other than `complete`. If found:

1. Read the state file and the log. Together they restore the campaign's knowledge; do not redo terminal units.
2. **Re-run the Step 2 reconciliation for the pending and in-progress units only.** This is cheap and safe, and it catches two things: a unit a previous session finished but was interrupted before checkpointing, and — if the project's revision has moved on — work done outside this skill in the meantime. Any unit whose end state now holds becomes `already-resolved`; the rest stay `pending`.
3. If the revision has changed, note it in the log's resumption line, but do **not** discard the backlog — remediation, unlike review, acts on the code rather than judging a snapshot, so a moved revision is normal and the reconciliation in step 2 above absorbs it. Only if the user explicitly asked for a fresh start do you rebuild the backlog from scratch.
4. Resume into the *existing* folder even if its date is no longer today's; add a dated resumption line to the log.

## Re-running after completion

If the state file is absent (a prior campaign completed) but the user invokes the skill again — because a new review ran, or new tech-debt was recorded — start a fresh campaign that **reads the existing log**, appends a new dated run section rather than overwriting it, and reconciles every candidate item against reality first (Step 2), so already-done work is recognised and not repeated.

## Environment caveat for the Claude.ai chat

The chat container's filesystem does not persist between sessions. Within a session the checkpoint discipline still recovers from interruptions; across sessions, resumption depends on the user re-uploading the partial folder with the project. Tell the user this if an interruption is foreseeable (for example, when they are low on credit). In Claude Code and Cowork the state persists on disk and resumption is automatic.
