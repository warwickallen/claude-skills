# Building the backlog, and managing overlap

The skill acts on two sources — a review's recommendations and a tech-debt register — that describe overlapping work in different vocabularies. The job of this step is to fuse them into **one ordered queue of work units**, each of which is implemented exactly once no matter how many recommendations or tech-debt entries it satisfies.

## Enumerating the recommendations

From the review folder (the latest `reviews/project-review-*/`):

- Parse `03-recommendations.md`: each `R-NN` row gives a title, **severity**, **effort**, and the finding IDs it **addresses**; each `R-NN` section gives the current state, the **intended end state** (the acceptance criteria), and the approach.
- Parse `04-improvement-prompts.md`: each `R-NN` has a self-contained prompt and a **Run after** line naming its prerequisites. Keep the prompt text — it is what you will hand to the subagent (see `subagent-dispatch.md`).
- If `04` is absent (an older or third-party review), you will synthesise the prompt from `03` at dispatch time; note this on the unit.

## Enumerating the tech-debt items

From the register located in Step 0:

- If the project ships a **resolver** (for example `scripts/get-tech-debt-record.pl`, which prints each record as a YAML map of `id`, `title`, `body`, and line numbers and exits with `matches − 1`), use it to enumerate and later to locate records precisely — it already knows the project's ID scheme and file location.
- Otherwise read the register directly, splitting on its entry headings. Preserve each entry's ID and its full body (the body usually states the fix and often cites the review IDs that motivated it).

## Detecting and merging overlap

Overlap between the two sources is expected and is exactly what causes rework if unmanaged. A review commonly records the same compromise both as a recommendation and, for durability, as a tech-debt entry that cites it — for example a register entry ending `(project-review-2026-07-11: F-CODE-02, F-ARCH-03, R-09.)`. Detect overlap three ways, most to least reliable:

1. **Explicit cross-reference.** A tech-debt entry that cites an `R-NN` or `F-` ID, or a recommendation whose approach names a tech-debt item. Treat these as authoritative.
2. **Same change.** Two items that name the same files and describe the same fix, even without a citation.
3. **Same finding.** A recommendation and a tech-debt entry that both trace to the same finding ID.

Merge every overlapping set into a single **work unit** `U-NN` carrying *all* the IDs it covers (`recommendation_ids`, `tech_debt_ids`, `finding_ids`). Implement the unit once; on success, clear every ID it carries (Step 3, step 5 in `SKILL.md`). Items with no overlap become singleton units.

When a unit carries both a recommendation and a tech-debt ID, the recommendation's improvement prompt is the richer specification — implement via that prompt, and afterwards remove/mark the tech-debt entry per the register's convention. **Do not** also run the project's tech-debt skill on the same item: that is the double-work this merge exists to prevent.

## Choosing how each unit is worked

- **Unit carrying a recommendation** (with or without tech-debt IDs): implement via the reviewer's improvement prompt and a directly dispatched subagent (`subagent-dispatch.md`).
- **Pure tech-debt unit, and the project has a tech-debt skill/agent** (e.g. `/td`, `/tech-debt`, `/techdebt`, detected in Step 0): delegate to it — it encodes this project's conventions (which record to touch, entry removal, changelog entries, commit policy). Pass it the record's ID segment or the resolver's output as that skill expects. Relay its result into the log like any other unit.
- **Pure tech-debt unit with no such skill:** implement directly via a subagent, building the prompt from the register entry's body (which usually contains the suggested fix), and afterwards remove/mark the entry per the register's convention.

Record the chosen route on each unit.

## Ordering the queue

Sort the units so that:

1. **Dependencies come first.** A unit listed in another's `run_after` must precede it. If the review's prompts declare an ordering ("run R-01 before R-06"), honour it; a merged unit inherits the union of its members' prerequisites.
2. **Then severity**, Critical → High → Medium → Low.
3. **Then effort**, Small before Large — quick wins first at equal severity.

Guard against cycles in the dependency graph; if one appears, break it by severity and note the decision.

## Reconciling against reality (Step 2)

This pass can do more of the campaign's real work than the dispatch that follows. A review may already be substantially implemented before it is formally actioned — earlier sessions, piecemeal fixes, out-of-band work — so a large share of units, possibly nearly all, may already be resolved on arrival. And it is *cheap*: file reads and `git log`, no subagents, no quota. Spend the effort here without stinting — proving an item done costs a few queries, whereas dispatching a subagent to redo finished work costs the dispatch, the verification of a redundant result, and possibly quota. Lean toward proving done.

For every unit, before it is dispatched, establish whether it is *already done*:

- Read the unit's intended end state and check the current codebase against it directly — does the file exist, is the field set, is the check in place?
- Search the git log for commits implementing it: by finding/recommendation/tech-debt ID, by the changed paths the recommendation names, or by the described change.
- A tech-debt entry that is still present in the register but whose fix is already in the code can occur on a resumed run or after out-of-band work — mark it `already-resolved` and, per the register's convention, still remove/mark the stale entry.

Mark satisfied units `already-resolved` with the evidence recorded so a reader can verify it; leave the rest `pending`. Doing this as its own deliberate pass — rather than lazily at dispatch — means the quota planning and ordering in Step 3 work from an accurate count of what actually remains, and a mostly-already-done campaign is recognised as such before a single subagent is spent.

## Removing or marking a resolved tech-debt entry

Follow the **register's own convention**, discovered in Step 0 — do not impose one:

- If the register's header or the project's `CLAUDE.md`/tech-debt skill says resolved entries are **deleted**, delete the whole entry (locate it by its ID heading, not by stored line numbers, which drift once editing begins) and remove any in-code references the entry names.
- If the register **marks** resolved entries (a status line, a strikethrough), mark it in that style and leave it in place.

When a project tech-debt skill exists, prefer letting *it* perform the removal, so the project's exact convention is applied — but still confirm the entry is gone (or marked) before you consider the unit resolved.
