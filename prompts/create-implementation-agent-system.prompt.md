Help me to create a system to launch an autonomous Implementation agents
according to these criteria:

1.  An Implementation Co-Ordinator agent will be launched by a script.
2.  The agent-launching script will be triggered periodically by a cron job.
3.  Before launching an Implementation Co-Ordinator agent, the script will
    check whether any of its Implementation Co-Ordinator agents are already
    running.  If there is an Implementation Co-Ordinator agent already running:
    - If that Implementation Co-Ordinator agent has been running for 6 hours or
      more, the script will kill it, then proceed.
    - If that Implementation Co-Ordinator agent has been running for less than
      6 hours, then script will not take any further action.
5.  Before launching an Implementation Co-Ordinator agent, but after the
    already-running-agent check, the script will check whether the user has
    enough quota/credit to do a useful amount of work; if not, the script will
    not take any further action.
6.  The script will pick a local repository from a predetermined list.
7.  Then the script will launch an Implementation Co-Ordinator agent, passing
    it the choosen repository's path as an input parameter.
8.  The Implementation Co-Ordinator agent will use a low-tier model.
9.  The Implementation Co-Ordinator agent will scan the repository for any
    obvious pending work.  It will look for:
    1.  failed GitHub runs,
    2.  tech-debt registers,
    3.  issues registers,
    4.  user stories,
    5.  implementation plans,
    6.  road maps.
10. The Implementation Co-Ordinator agent will select a single stand-alone unit
    of work that is clearly scoped and adequitely refined.
11. The Implementation Co-Ordinator agent will priortise the work according to
    the list order in Criterion 9 (above).
12. The Implementation Co-Ordinator agent will launch an Implementor agent to
    conduct the work.
13. The Implementor agent will use the optimal model to save cost yet ensure the
    task is likely to be done correctly the first time.
14. The Implementation Co-Ordinator agent will pass to the Implementor agent any
    useful information that it has already discovered.
15. If the selected task is a tech-debt item, and there exists a tech-debt skill
    (often `/td`, `/techdebt` or `/tech-debt`) in the target reposirty, then the
    Implementor agent will be launched with that skill.
16. Once the Implementor agent has completed its task, it will ensure the
    documentation is updated to make it clear that that task has been resolved.
17. Once the Implementor agent completes its task and reports back to the
    Implementation Co-Ordinator agent, the Implementation Co-Ordinator agent
    will lauch a higher-tier model Reviewer agent to confirm (and correct if
    necessary) the Implementor agent's work.
18. The Implementation Co-Ordinator agents will keep their on log of all work
    done.  This is in addition to any in-repo record keeping that the
    Implementor agents might do.
19. If the Implementation Co-Ordinator agent cannot discover any adequately
    scoped, clearly defined item of work, it will finish without launching any
    Implementator agents.  The Implementation Co-Ordinator should not make
    guessing or assumptions; if it is in doubt, it should refrain from doing
    anything.

