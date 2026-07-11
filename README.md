# Claude Skills

A growing collection of [Agent Skills] for Claude: self-contained folders of
instructions, reference material, and (where needed) scripts that teach Claude
how to carry out a specific task in a reliable, repeatable way.  Every skill
works the same way wherever you use it: give it to a Claude product, describe
what you want, and Claude loads the relevant skill automatically.

## Skills

| Skill            | Summary |
| ---------------- | ------- |
| [Project Review] | Runs a broad, evidence-based review of a software project and produces a set of linked reports covering a summary, detailed findings, prioritised recommendations, a tech-debt register, and ready-to-use prompts for an AI agent to implement each recommendation. |

This table will grow as new skills are added to the repository.

## How to use these skills

Every skill here is just a folder containing a `SKILL.md` file, and sometimes
some supporting reference files or scripts.  How you get that folder in front of
Claude depends on which Claude product you use, and on whether you want a single
skill, a handful, or the whole collection.  The three options below cover the
common cases, and you can mix them as needed.

### Decide what you want first

- **Just one skill, or a few specific ones.**  
  Go straight to "Option 2" or "Option 3" below and grab only the folders you
  need.
- **Every skill, and you want to keep track of new ones as they're added.**  
  Use "Option 1" to get your own copy of the whole repository, then use "Option
  2" or "Option 3" to load the skills into Claude.
- **Every skill, as a one-off, with no ongoing link back to this repository.**  
  Skip straight to "Option 2" or "Option 3" and download the whole repository.

### Option 1: Use the template, or fork the repository

This repository is set up as a GitHub template.  On the repository's main page,
click the green **Use this template** button, then **Create a new repository**,
and GitHub creates your own independent copy under your account.  This is the
best starting point if you intend to add, remove, or customise skills of your
own.

A template-based copy has no ongoing link back to this repository, so you will
not be notified about, or automatically receive, new skills added here in
future.  If you would rather keep that link, click **Fork** instead of "Use this
template"; a fork can be brought up to date at any time with GitHub's **Sync
fork** button.

Either way, having your own copy of the repository is only the first step.  You
still need to get the individual skill folders into whichever Claude product you
use, using Option 2 or Option 3 below.

### Option 2: Download a ZIP file and upload it in a Claude app

Use this option for Claude.ai on the web, the Claude desktop app, the Claude
mobile app, Claude Cowork, and the Claude for Excel, PowerPoint, Word, and
Outlook add-ins.  All of these load custom skills through a settings screen
rather than through a file system, so this option works on Windows, macOS,
Linux, iOS, and Android alike; all you need is a web browser and a way to handle
ZIP files.

Claude requires **one ZIP file per skill, with `SKILL.md` at the top level of
the ZIP** rather than nested inside a folder.  This means that even if you want
every skill in the repository, you will still upload each one separately.

**To get a ZIP file for a single skill:**

1.  Open the skill's folder on GitHub (for example, this repository's
    `skills/project-review` folder) and copy its web address from your browser's
    address bar.
2.  Go to a browser-based GitHub folder-downloader, such as
    [download-directory.github.io], paste the address in, and download the ZIP
    it generates.  This gives you a ZIP with `SKILL.md` already at the top
    level, ready to upload, with nothing to install and nothing to unzip and
    re-zip yourself.
3.  Repeat for each additional skill you want.

If you would rather avoid a third-party site, you can get the same result
yourself: click the green **Code** button on the repository's main page, choose
**Download ZIP**, extract it, then compress the single skill folder you want
into its own new ZIP file.

**To upload a ZIP file into Claude:**

1.  Open **Settings > Capabilities** and turn on **Code execution and file
    creation**, if it isn't already on.  On a Team or Enterprise plan, an
    organisation owner enables this instead, in **Organization settings >
    Skills**.
2.  Go to **Customize > Skills**.
3.  Click **+**, then **+ Create skill**, then **Upload a skill**.
4.  Select the ZIP file you downloaded.
5.  Repeat for each additional skill.

On a phone, the same **Settings > Capabilities** and **Customize > Skills**
screens are available within the Claude app.  When prompted for a file, use your
phone's file manager to find the ZIP you downloaded (for example, the built-in
Files app on iOS, or a file manager or archive app such as ZArchiver on
Android); the same kind of app will also let you extract and re-compress a
folder if you are using the "Download ZIP" fallback above rather than a
folder-downloader site.

### Option 3: Link or copy the skill folders into your own working directory

Use this option for Claude Code, or any other tool that reads skills directly
from the file system (this also includes the Claude Agent SDK, which uses the
same convention).  Personal skills, available to every project, normally live in
`~/.claude/skills/`; project-specific skills live in a `.claude/skills/` folder
inside a particular project.

First, get the repository onto your machine.  Git commands are the same on
Windows, macOS, and Linux, provided Git is installed.  For the whole repository:

```bash
git clone https://github.com/warwickallen/claude-skills.git
```

Or, if you only want specific skills but would still like to be able to run `git
pull` for future updates, use a sparse checkout instead:

```bash
git clone --no-checkout https://github.com/warwickallen/claude-skills.git
cd claude-skills
git sparse-checkout init --cone
git sparse-checkout set skills/project-review
git checkout main
```

Then either copy or symlink the skill folder(s) you want into your skills
directory.  A symlink stays up to date whenever you `git pull` the source
repository; a copy is independent, and safe to edit without affecting the
original.

**macOS and Linux:**

```bash
mkdir -p ~/.claude/skills

# Copy.
cp -r claude-skills/skills/project-review ~/.claude/skills/

# Or symlink, as an alternative to copying.
ln -s "$(pwd)/claude-skills/skills/project-review" ~/.claude/skills/project-review
```

**Windows (PowerShell):**

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills" |
  Out-Null

# Copy.
Copy-Item -Recurse claude-skills\skills\project-review `
  "$env:USERPROFILE\.claude\skills\project-review"

# Or symlink, as an alternative to copying (run PowerShell as Administrator, or
# enable Developer Mode first).
New-Item -ItemType SymbolicLink `
  -Path "$env:USERPROFILE\.claude\skills\project-review" `
  -Target "$(Resolve-Path claude-skills\skills\project-review)"
```

Every folder inside this repository's `skills/` directory is a skill, so to load
several, or all of them, run the same copy or symlink command again for each
folder you want.  Replace `~/.claude/skills/` (or
`$env:USERPROFILE\.claude\skills\`) with a project's own `.claude/skills/`
folder if you would rather make a skill available only within that one project,
rather than in every project.

---

Copyright 2026 Warwick Allen  
Licensed under CC BY 4.0 — see [LICENCE]

[Agent Skills]:
https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills

[LICENCE]:
LICENCE

[Project Review]:
skills/project-review/SKILL.md

[download-directory.github.io]:
https://download-directory.github.io/

