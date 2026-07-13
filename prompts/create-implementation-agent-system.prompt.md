# Scheduled Autonomous Implementation Agent System

## Your Role

You are both:

1.  A prompt-engineering expert, and
2.  A software engineer with experience in building autonomous agent systems.

## The Entities

This document refers to five types of entities:

1. The **Cronjob**;
2. The **Agent-Launching Script** (the Script);
3. The **Implementation Co-Ordinator Agent** (the Co-Ordinator);
4. The **Implementor Agent** (the Implementor);
5. The **Reviewer Agent** (the Reviewer).

## Your Task

Create a system to launch autonomous agents according to these criteria:

1.  A Co-Ordinator will be launched by the Script.

2.  The Script will be triggered periodically by the Cronjob.

3.  Before launching a Co-Ordinator agent, the Script will check whether any
    Co-Ordinators are already running.  For any Co-Ordinator that is already
    running:
    - If that Co-Ordinator has been running for 6 hours or more, the Script
      will kill it, then proceed.
    - If that Co-Ordinator has been running for less than 6 hours, the Script
      will not take any further action; it will be relaunched by the Cronjob at
      the next scheduled time.
    - **N.B.:** Something has gone wrong if there are multiple Co-Ordinators
      running concurrently; nevertheless, the same rules apply to each of them.

4.  Before launching an Co-Ordinator, but after the check for
    already-running Co-Ordinators, the Script will check whether the user has
    enough tokens/quota/credit to do a useful amount of work; if not, the Script
    will not take any further action.

5.  The Script has a list of local repositories.  It will sort that list
    according to the most recent commit timestamp, with the least recently
    updated repository at the top of the list.

6.  Then the Script will launch a Co-Ordinator, passing it the stored
    repository list as an input parameter.

7.  The Co-Ordinator will use a low-tier model.

8.  The Co-Ordinator will work through the list of repositories, top-to-bottom.
    For each repository, it will look for any obvious pending work.  It will
    look for, in order of priority:
    1.  failed GitHub runs,
    2.  tech-debt registers,
    3.  issues registers,
    4.  user stories,
    5.  implementation plans,
    6.  road maps.

9.  The Co-Ordinator will select the first stand-alone unit of work that is
    clearly scoped and adequitely refined and is not blocked (see Criterion 18).

10. The Co-Ordinator will launch an Implementor to conduct the work.

11. The Implementor will use the optimal model to save cost yet ensure the task
    is likely to be done correctly the first time.

12. The Co-Ordinator will pass to the Implementor any useful information that
    it has already discovered.

13. If the selected task is a tech-debt item, and there exists a tech-debt skill
    (often `/td`, `/techdebt` or `/tech-debt`) in the target reposirty, then the
    Implementor will be launched with that skill.

14. The Implementor will work on its own feature branch.

15. Once the Implementor has completed its task, it will ensure the
    documentation is updated to make it clear that that task has been resolved.

16. The Implementor will then raise a PR for its work to be merged.  They will
    tag the PR with a label that indicates that it was created by an autonomous agent.

17. Once the Implementor completes its task, including documentation, and
    reports back to the Co-Ordinator, the Co-Ordinator will lauch a higher-tier
    model Reviewer to confirm (and correct if necessary) the Implementor's PR.

18. The Co-Ordinator will keep a log (shared between all Co-Ordinators) of all
    work done.  This is in addition to any in-repo record keeping that the
    Implementor agents might do.  Along with other useful information, this log
    will record items that the Implementors were unable to do, so other
    Implementors won't be assigned those items until the blockers have been
    removed.

19. If the Co-Ordinator cannot discover any adequately scoped, clearly defined
    item of work, it will finish without launching any Implementors.  The
    Co-Ordinator should not make guesses or assumptions; if it is in doubt, it
    should refrain from doing anything.
