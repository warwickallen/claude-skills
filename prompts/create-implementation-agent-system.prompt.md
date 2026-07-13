# Scheduled Autonomous Implementation Agent System

## Role

You are acting as both:

1. A prompt-engineering expert, and
2. A software engineer experienced in building autonomous agent systems.

## Entities

This document refers to five automated entities and one human role.

1. The **Cronjob**.
2. The **Agent-Launching Script** (the Script).
3. The **Implementation Co-Ordinator Agent** (the Co-Ordinator).
4. The **Implementor Agent** (the Implementor).
5. The **Reviewer Agent** (the Reviewer).
6. The **Human Reviewer**, who gives final approval and performs the merge on every pull request. The Human Reviewer is not launched by any part of this system, and acts through the ordinary GitHub pull-request process. See "The Human Gate," below, for further detail.

## System Parameters

The following parameters are referenced throughout this document. Each one must be filled in, or its proposed default confirmed, before this document is used as a build prompt. Defaults are collected, together with the other assumptions made in this revision, in "Assumptions Made In This Revision," below.

- `REPO_LIST_PATH`: the location of the file that stores the list of local repositories (see point 6). Default: a JSON file, at a path you specify, containing an array of absolute repository paths.
- `SHARED_LOG_PATH`: the location of the shared work log (see point 24).
- `CRON_INTERVAL`: how often the Cronjob fires. Default: hourly.
- `COORDINATOR_MODEL`: the low-tier model used by the Co-Ordinator.
- `IMPLEMENTOR_MODEL_POLICY`: the rule the Co-Ordinator uses to choose a model for each Implementor. See point 13 and the open questions.
- `REVIEWER_MODEL`: the higher-tier model used by the Reviewer.
- `QUOTA_CHECK_METHOD`: how the Script determines the user's remaining tokens, quota, or credit, and the threshold below which it stands down. See the open questions.
- `PR_LABEL`: the label applied to every pull request raised by an Implementor. Default: `autonomous-agent`.
- `BRANCH_NAMING_CONVENTION`: the naming pattern for an Implementor's feature branch. Default: `agent/<repo-slug>/<short-task-slug>`.

## The Human Gate

The only branch this system protects is each repository's default branch (`main`, or its equivalent). No agent — Implementor, Co-Ordinator, or Reviewer — may push to that branch directly, or approve or merge a pull request that targets it, at any point; a human must do both. Every other branch is entirely at the agents' disposal: an Implementor's feature branch, and anything the Reviewer does to it, may be created, amended, rebased, force-pushed, or discarded by the agents as they see fit, without any human involvement.

Because every Implementor branch is created from the default branch (point 17) and its pull request targets the default branch, this means, in practice, that every pull request this system raises passes through the human gate. The Reviewer's job (points 21 to 23) is to check the Implementor's work, and correct it directly on the feature branch where it can, so that the Human Reviewer's time is spent on work that is already close to mergeable, rather than on catching basic errors. This is the only point in the whole system at which a human is required; every other step in this document is designed to run unattended.

## Task

Build the system described below.

### The Cronjob and the Script

1. The Cronjob triggers the Script periodically, at the interval given by `CRON_INTERVAL`. Default: hourly.

2. Before launching a Co-Ordinator, the Script checks whether any Co-Ordinators are already running, and how long each one has been running for.

3. For each Co-Ordinator that has been running for six hours or more, the Script kills it, along with any Implementor or Reviewer that it launched (see point 4), and then proceeds to point 5. If, after this, at least one Co-Ordinator is still running (that is, one that started fewer than six hours ago), the Script takes no further action this cycle; it will be triggered again by the Cronjob at the next scheduled time. If no Co-Ordinator was running to begin with, the Script proceeds directly to point 5.

4. When the Script kills a stale Co-Ordinator, it also terminates any Implementor or Reviewer that Co-Ordinator had launched. Because only the default branch is protected (see "The Human Gate," above), the Script is free to leave, reset, or delete whatever feature branch was left behind; this document does not mandate which, since it is a matter of housekeeping rather than of correctness. If the state is left as it is, and the next Co-Ordinator to examine that repository cannot make sense of it, it treats the item as blocked and records why, per point 24.

   **Note:** more than one Co-Ordinator running at the same time indicates a fault elsewhere in the system, since the Script is not designed to launch a second one while a first is active. The rules above still apply individually to each Co-Ordinator found, but the Script should also record this condition as a warning in the shared log, since it should not occur during normal operation.

5. Once the check in points 2 to 4 allows it to proceed, the Script checks whether the user has enough tokens, quota, or credit remaining to do a useful amount of work, using `QUOTA_CHECK_METHOD`. If not, the Script takes no further action this cycle.

6. The Script reads the repository list from `REPO_LIST_PATH`, and sorts it by the timestamp of the most recent commit on each repository's default branch, with the least recently updated repository placed first.

7. The Script launches a Co-Ordinator, passing it the sorted repository list.

### The Co-Ordinator

8. The Co-Ordinator uses `COORDINATOR_MODEL`.

9. The Co-Ordinator works through the repository list in the order it was given. For each repository, in turn, it checks for pending work in the following order of priority, and stops checking further categories for that repository as soon as one category yields at least one candidate item:
   1. Failed GitHub runs.
   2. A tech-debt register.
   3. An issues register.
   4. User stories.
   5. Implementation plans.
   6. Road maps.

   If a repository yields no candidate item in any of these categories, the Co-Ordinator moves on to the next repository in the list. This means the Co-Ordinator may select a lower-priority item from the least recently updated repository in preference to a higher-priority item from a repository further down the list. This is intentional: the ordering established in point 6 already reflects which repository is most overdue for attention, and takes precedence over the category ordering within a single repository.

10. A candidate item is **blocked** if the shared log (point 24) already records that a previous Implementor was unable to complete it, and the log does not also record that the blocker has since been removed. The Co-Ordinator excludes blocked items from selection.

11. From the unblocked candidate items found in point 9, the Co-Ordinator selects the first one that is a stand-alone unit of work, is clearly scoped, and is adequately refined. The Co-Ordinator does not guess or make assumptions when judging whether an item meets this bar. If it is in doubt about a given item, it treats that item as not meeting the bar, and moves on to the next candidate.

12. If no candidate item meets the criteria in point 11, the Co-Ordinator does not select anything, and finishes without launching an Implementor.

13. If a suitable item was selected, the Co-Ordinator launches an Implementor to carry out the work, choosing a model for the Implementor according to `IMPLEMENTOR_MODEL_POLICY` (this policy is not yet defined; see the open questions below).

14. The Co-Ordinator passes to the Implementor any useful information it has already gathered while locating and evaluating the item — for example, the item's source location, related context found in the same register, and the reasoning behind why the item was judged unblocked and adequately scoped.

15. If the selected item is a tech-debt item, and the target repository contains a tech-debt skill (for example, one named `/td`, `/techdebt`, or `/tech-debt`; see the open questions below for how to handle other names), the Co-Ordinator launches the Implementor with that skill.

### The Implementor

16. The Implementor uses the model chosen for it in point 13.

17. The Implementor works on its own feature branch, named according to `BRANCH_NAMING_CONVENTION` and branched from the repository's default branch.

18. Once the Implementor has completed the task, it updates the relevant documentation (for example, the tech-debt register, issues register, or user-story entry that the item came from) to show that the item has been resolved.

19. The Implementor then raises a pull request for its work, and tags it with `PR_LABEL`, to show that it was created by an autonomous agent.

20. The Implementor reports back to the Co-Ordinator once the task, including the documentation update and the pull request, is complete.

### The Reviewer

21. Once the Implementor has reported back, the Co-Ordinator launches a Reviewer, using `REVIEWER_MODEL`, to check the Implementor's pull request.

22. The Reviewer checks the pull request against the original item of work, and against the target repository's own standards and conventions. Where it finds a problem it can fix directly, it corrects the Implementor's branch itself — by amending, adding commits to, or otherwise rewriting that branch, as it judges best, since the branch is not protected. Where it finds a problem it cannot fix with confidence, it leaves a review comment describing the problem, for the Human Reviewer's attention.

23. The Reviewer does not approve or merge the pull request. Once its check is complete, the pull request is left open and ready for the Human Reviewer, per "The Human Gate," above.

### Logging

24. The Co-Ordinator keeps a log, shared between all Co-Ordinators, of all work done. This is in addition to any in-repo record-keeping that an Implementor performs. The log records, at minimum: which item was selected and from which repository; which Implementor and Reviewer model were used; the outcome (a pull request raised, no suitable item found, or an item attempted and not completed); and, for any item an Implementor was unable to complete, enough detail for a future Co-Ordinator to determine both that the item is blocked, and whether the blocker has since been removed.

## Deliverables

Building this system means producing all of the following.

1. The Cronjob definition or schedule configuration.
2. The Script, implementing points 1 to 7.
3. The Co-Ordinator's operating instructions (a system prompt, or equivalent), implementing points 8 to 15.
4. The Implementor's operating instructions, implementing points 16 to 20.
5. The Reviewer's operating instructions, implementing points 21 to 23.
6. The shared log's schema and storage mechanism, implementing point 24.
7. A short document explaining how to set each System Parameter, and how to install the Cronjob.

## Assumptions Made In This Revision

The following assumptions have been made in order to make this document buildable. Each is a reasonable default, and each is easy to change; review them, and correct any that do not suit your environment.

- The repository list (`REPO_LIST_PATH`) is a JSON file containing an array of absolute repository paths.
- Repositories are sorted by the most recent commit timestamp on their default branch only, not across all branches.
- The branch-naming convention is `agent/<repo-slug>/<short-task-slug>`.
- The pull-request label is `autonomous-agent`.
- A tech-debt skill is discovered only by checking for the three names given in point 15. No further search is performed.
- The shared log is a single file at `SHARED_LOG_PATH`, with one entry appended per event. A format such as JSON Lines is suitable, provided appends are safe under the concurrency rules in points 2 to 4, which should in practice prevent more than one Co-Ordinator writing to it at once.

## Open Questions

1. Which models should be used for `COORDINATOR_MODEL` and `REVIEWER_MODEL`, and what should `IMPLEMENTOR_MODEL_POLICY` actually be — that is, on what basis should the Co-Ordinator judge which model the Implementor needs?
2. What should `QUOTA_CHECK_METHOD` be — is there a command or an API that can be used?
