---
name: factory
description: Run the software factory loop. Use when the user invokes /factory to take a feature through spec, build, review, and approval, or to run/approve/rework factory jobs.
---

# Factory — orchestrator

You are the orchestrator. You run the loop below, spawn every agent, and you are
the **only writer of `factory/board.json`**. Agents get context from files, not
from the conversation, and each agent writes only its own file.

## The loop (edit this to change the factory)

```
                   ┌──────────────────┐
                   │     feature      │
                   └─────────┬────────┘
                             ▼
                   ┌──────────────────┐
                   │   spec-writer    │
                   │qwen3.8-flash-next│
                   └─────────┬────────┘
                             ▼
                   ┌──────────────────┐
                   │     builder      │◄────────────────────┐
                   │qwen3.8-flash-next│                     │
                   └─────────┬────────┘                     │
        ┌─────────────┬──────┴──────┬─────────────┐         │
        ▼             ▼             ▼             ▼         │
  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐   │
  │  security │ │     ux    │ │ ui design │ │    code   │   │
  │qwen3.8-flash-next│ │qwen2.5-coder│ │qwen2.5-coder│ │qwen2.5-coder│   │
  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ └─────┬─────┘   │
        └─────────────┴──────┬──────┴─────────────┘         │
                             ▼                              │
                   ┌──────────────────┐   any CHANGES:      │
                   │   WAIT FOR ALL   ├─────────────────────┘
                   │   4 reviews in   │   resume builder
                   └─────────┬────────┘   (max 2 rounds)
                             ▼ all PASS
                   ┌──────────────────┐
                   │     approver     │
                   │qwen3.8-flash-next│
                   └─┬───────────────┬┘
             APPROVE │               │ ESCALATE
                     ▼               ▼
              ┌─────────────┐ ┌─────────────┐
              │merge to main│ │ needs-human │ ◄── /factory approve
              └─────────────┘ └─────────────┘
```

## Repo facts (agents rely on these)

- Language: **Go** (module `x-opencode-web`). Test command: `go test ./...`
- Conventions: gofmt; table-driven tests; one package per feature under the
  repo root. If the repo grows, re-inspect and update this section.

## Commands

- `/factory <feature>` — run a new job through the loop.
- `/factory next` — take the first unchecked `- [ ]` item in `factory/backlog.md`,
  check it off, then run it as a new job.
- `/factory approve <job-id>` — merge a `needs-human` job's branch into main,
  set its stage to `done`.
- `/factory rework <job-id> <note>` — append the note to the job's latest round
  as `rework-note.md`, set stage back to `build`, and resume the builder.

## Starting a job

1. Pick the next id: `NNN-<slug>` (e.g. `004-health-check`).
2. `git checkout main && git checkout -b factory/<job-id>`
3. Create `factory/jobs/<job-id>/` and write `feature.md` containing the raw
   feature text.
4. Add the job to `factory/board.json` with `"stage": "spec"`, `"round": 0`,
   and all four reviews `"pending"`.

## The loop

1. **spec-writer** — spawn the `spec-writer` subagent. It reads
   `factory/jobs/<job-id>/feature.md` and writes `spec.md`.
2. **builder** — spawn the `builder` subagent **named `builder-<job-id>`**.
   It reads `spec.md`, works and commits on branch `factory/<job-id>`, runs
   `go test ./...` against the spec's acceptance criteria, and writes `build.md`.
   Remember the returned task id — you will resume this same builder.
3. **reviews (one round)** — create `factory/jobs/<job-id>/round-<N>/`.
   Spawn all four reviewers (`review-security`, `review-ux`, `review-ui`,
   `review-code`) **in parallel**, each told the round folder path. Each writes
   `review-<name>.md` in that folder starting with `VERDICT: PASS` or
   `VERDICT: CHANGES`.
4. **WAIT FOR ALL** — a round is done only when all four review files exist in
   the round folder. Never resume the builder mid-round. Update each review's
   verdict in `board.json` as files land.
5. **any CHANGES** — if any verdict is CHANGES and `round < 2`: **resume the
   same builder** (task id from step 2) pointing it at `round-<N>/`, then go to
   step 3 with `round-<N+1>`. If `round == 2`, go to the approver regardless.
6. **approver** — spawn the `approver` subagent. It reads the round folder and
   writes `decision.md` starting with `APPROVE` or `ESCALATE`.
7. **outcome** —
   - `APPROVE`: `git checkout main && git merge --no-ff factory/<job-id>`,
     set stage `done`.
   - `ESCALATE`: set stage `needs-human`. A human later runs
     `/factory approve <job-id>` to merge it.

## board.json

You are the only writer. Update it after every stage change so the dashboard
stays truthful. Shape:

```json
{ "jobs": [ { "id": "003-rate-limiting", "branch": "factory/003-rate-limiting",
  "stage": "review", "round": 2,
  "reviews": { "security": "CHANGES", "ux": "PASS", "ui": "pending", "code": "PASS" } } ] }
```

`stage` is one of: `spec`, `build`, `review`, `decision`, `done`, `needs-human`.

## Rules

- Agents get context from files, not the conversation, and write only their own file.
- Each review starts with `VERDICT: PASS` or `VERDICT: CHANGES`; `decision.md`
  starts with `APPROVE` or `ESCALATE`.
- The builder works and commits on `factory/<job-id>` and tests against the
  spec's acceptance criteria.
- Spawn the builder with a name (`builder-<job-id>`) and resume that same
  builder for each new round, pointing it at the round folder.
- Max 2 review rounds per job.

## Dashboard

`factory/dashboard.html` polls `board.json`. To view it:
`cd factory && python3 -m http.server` → http://localhost:8000/dashboard.html
