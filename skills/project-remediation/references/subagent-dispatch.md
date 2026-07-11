# Dispatching subagents

Each unit's real work is done by a subagent. The skill's value at this step is three judgements: **which** tier of subagent, **what** to tell it, and **whether** what it returns is real. Get those right and the campaign is cheap, correct, and honest.

## Choosing the model tier

Match the subagent's model tier to the unit's difficulty, not to a fixed default. Refer to tiers **generically** — low-cost, mid-cost, high-capability — and map them onto whatever models your environment offers (its cheapest capable model is the low tier, its strongest the high tier). Naming specific models here would date the skill, exactly as `project-review` avoids naming them in its prompts.

The decisive principle: **a failed cheap attempt that must be redone costs more than doing it right once**, and a high-capability tier spent on mechanical work is waste. Use the unit's effort and severity, and the improvement prompt's own cost guidance, to place it:

| Unit character | Tier |
|---|---|
| Mechanical, fully specified: renames, applying a documented pattern across files, adding a licence file, writing tests for specified behaviour, formatting (typically Small effort) | Low-cost |
| Ordinary implementation against clear acceptance criteria (typically Medium effort) | Mid-cost |
| Ambiguous, cross-cutting, design-level, security-critical, or Large-effort work; and reviewing cheaper subagents' output where the risk warrants it | High-capability |

A unit's severity can raise its tier: a Critical or security-relevant change is implemented and reviewed at a high-capability tier even if part of it (say, its tests) could be delegated cheaply. When in doubt between two tiers, pick the higher for correctness-critical work and the lower for reversible, well-specified work.

Subagents may spawn their own subagents; a Large unit handed to a high-capability subagent will often decompose itself and delegate mechanical parts downward. That is intended — do not forbid it.

## What to send the subagent

Send the **reviewer's improvement prompt verbatim** as the body of the task. It was written to be self-contained — project context, the problem with evidence, acceptance criteria, constraints, verification, a cost policy, and a deliverable — precisely so it could be pasted into a fresh agent. Reproducing it faithfully is the point of "noting the project reviewer's suggested prompts".

Wrap it in a short **orchestration header** that the prompt itself cannot know:

- Which repository and review folder this is part of, and the unit ID.
- **A commit-policy override.** The reviewer's prompt often ends "produce a single commit"; override it to match this run's `commit_policy`:
  - **`working-tree`** (the default): *"Do not commit or push. Leave your changes in the working tree and report a suggested Conventional Commit subject line instead."* This keeps commit control with the user, matching the environment's default and the project's own tech-debt skill.
  - **`branch-per-unit`** (when the user wants commits): tell the subagent which branch it is on — one the orchestrator created for this unit off the integration-branch tip — and instruct it to *commit its own work on that branch and no other, authoring a good Conventional Commit message from the context it has, and not to push, merge, or switch branches.* The subagent may make more than one commit if that is natural; the orchestrator squashes them at merge time. Letting the subagent author the message is the point — it holds the exact context, so the orchestrator never has to reconstruct it from a mingled diff.
- A instruction to **report back** concretely: the files changed, the exact verification commands run and their output, anything it could not do, and — if it discovered the recommendation was already satisfied or is no longer valid — to say so rather than manufacture a change.
- For a **merged unit**, the IDs it covers, so the subagent's report can be tied to all of them.

If the review has no `04-improvement-prompts.md`, synthesise the prompt from the recommendation's `03` entry, following the same self-contained shape (context, problem with paths, acceptance criteria, constraints, verification, cost policy, deliverable). Keep it short — padding wastes the very tokens the cost policy saves.

When delegating a pure tech-debt unit to the project's own tech-debt skill (e.g. `/td`), you do not write the prompt at all — that skill does. Pass it the ID segment it expects and let it apply the project's conventions; your job is then only verification and recording.

## Verifying before marking resolved

Never mark a unit `resolved` on the subagent's assurance alone. Independently confirm the intended end state:

- Run the prompt's stated verification yourself — the tests, build, linter, or audit it names — or, where re-running is expensive, spot-check the specific artefacts the acceptance criteria describe (the file exists, the field is set, the check is present, the vulnerable pattern is gone).
- Confirm the change is scoped: the subagent did not also alter unrelated files, break the build, or leave the suite red.
- For a security or data unit, review the actual diff at a high-capability tier — the class of change where a plausible-looking but wrong fix is most dangerous.

Only when verification passes is the unit `resolved`. If it fails:

- **Retry** once, and consider raising the tier if a cheap attempt produced a wrong or incomplete result.
- If it still fails, mark the unit `blocked` (a genuine obstacle: a missing credential, an upstream bug, a failing test the fix cannot satisfy) or `deferred` (a conscious postponement, e.g. a dependency major-bump that churns golden fixtures), and record the reason in the log. A recommendation whose acceptance criteria cannot be met without violating a constraint is reported back, not forced through — the reviewer's criteria are the contract.

## Integrating under `branch-per-unit`

When the run commits (`commit_policy` is `branch-per-unit`), the branches form a clean history so the orchestrator never has to untangle a shared working tree:

- **One integration branch per campaign**, cut once off the starting HEAD (`remediation/<date>`). The user's default branch is left untouched; all clean per-unit commits accumulate here.
- **One branch per unit**, cut off the *current integration-branch tip* at dispatch — not off the original HEAD. Because dependencies are ordered earlier in the queue and merged before their dependents dispatch, branching off the tip means a dependent unit's subagent sees its prerequisites' committed work, exactly as sequential subagents in a shared tree would.
- **Squash-merge on green.** Only after the orchestrator's own verification passes, squash-merge the unit branch into the integration branch as a single commit, reusing the subagent's authored message. Squashing collapses any messy intermediate commits into one clean, reviewable unit of history. Record the resulting commit hash as the unit's evidence; the unit branch can then be deleted.
- **Never squash-merge a unit that did not verify.** A `blocked` or `deferred` unit's branch is left unmerged (and noted in the log) so nothing unverified reaches the integration branch.

The final integration branch is a linear, one-commit-per-resolved-unit history. The user's remaining action is a single review-and-merge (or a PR) into their default branch — the "series of squash-merges" is already done, cheaply, by the orchestrator as each unit passed. This is deliberately the opposite of leaving every unit's changes mingled in one working tree for someone to reconstruct commit boundaries and messages afterwards.

## Recording the outcome

For every terminal unit, the log entry records: the IDs cleared, the route taken (which tier, or which tech-debt skill), what changed (paths), the verification commands and their result, the suggested Conventional Commit subject (and, under `branch-per-unit`, the squash-merge commit hash on the integration branch), and — for `deferred`/`blocked` — the reason and any follow-up. Then clear every ID the unit carries, as `SKILL.md` Step 3 describes, and checkpoint.
