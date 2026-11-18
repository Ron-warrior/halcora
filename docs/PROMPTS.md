# Prompts

Copy-paste these to start a session with a smaller model. They assume the model
can read the repository and nothing else.

---

## First prompt, empty session

    You are continuing work on the Halcora repository:
    https://github.com/Ron-warrior/halcora

    Read these files, in this order, before doing anything else:
      1. AGENTS.md
      2. docs/STATE.md
      3. docs/TASKS.md
      4. docs/HANDOFF.md

    Then tell me, in under 150 words: what has been verified, what has never
    been tested, and which task is next. Do not change any files yet.

    Rules you must keep to all session:
    - You cannot build, boot or test anything. Never say something works. Say
      what CI said and what I told you.
    - Do the first unfinished task in docs/TASKS.md only.
    - Keep main buildable. Half-finished work goes on a branch.
    - Read any file before editing it.
    - At the end of the session, update docs/STATE.md.

---

## When CI fails

    The ISO workflow failed. Here is the last failing step's log:

    <paste the log>

    Find the cause using the failure-to-action table in docs/HANDOFF.md. Fix
    exactly one thing. Tell me what you changed and why before you push, and do
    not claim it will work — say what the next CI run will tell us.

---

## When I have booted it

    Boot report:

    <paste the filled-in template from docs/TESTING.md>

    Fix only the first problem in the boot sequence. If the report is missing
    something you need to diagnose it, ask me for that specific thing rather than
    guessing.

---

## When I want to stop for the day

    Before you finish: update docs/STATE.md with what CI verified, what I
    reported, what you changed, and what the next task is. Then commit and push
    everything. Confirm the working tree is clean.

---

## When it has drifted

    The repository has changed since docs/STATE.md was written. Follow the
    "If the repo has changed since this was written" section of
    docs/HANDOFF.md, re-verify the state against the code, and update STATE.md
    before starting on any task.

---

## When you have an Arch machine

    I have an Arch machine. Walk me through `packages/build.sh` and tell me what
    each failure means as it happens.

    Then, if the packages build, check that
    `plasma-apply-lookandfeel --list` shows both ids, and tell me what the
    desktop looks like with each layout applied. That report is worth more than
    the packages themselves: it is the first time any of this has run.

---

## Picking up the packages

    The packages on main have never been built. Read docs/STATE.md first.

    `packages/build.sh` has never completed. Everything on `main` under iso/ is
    built by CI; nothing under packages/ is. Say which you mean when you say
    "verified".

    Do not merge or rewrite history without telling me first.

