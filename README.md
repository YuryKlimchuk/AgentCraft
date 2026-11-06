# AgentCraft

AgentCraft is an engineering methodology for AI-assisted software development. It provides
reusable engineering assets for AI coding agents:

- **Development workflow** — eight stages with explicit Quality Gates and user-approval checkpoints.
- **Agents** — specialized subagent definitions (Analyst, Architect, QA Planner, Developer, Reviewer, QA Tester).
- **Skills** — reusable engineering knowledge (DDD, hexagonal architecture, Spring, testing, REST, OpenSpec, and more).
- **Platform configuration** — Pi and `pi-subagents` setup.
- **OpenSpec configuration** — instructions and templates for change specifications.
- **Setup script** — installs and updates AgentCraft assets in a target repository.

## Layout

| Path | Contents |
|------|----------|
| `AGENTS.md` | Project instructions for the AgentCraft repository itself |
| `templates/AGENTS.md` | Generic project-instructions template copied into target repositories |
| `agents/` | Subagent definitions (distributed to `.pi/agents`) |
| `skills/` | Engineering skills (distributed to `.pi/skills`) |
| `docs/` | Workflow, orchestrator, and quality-gate documentation |
| `openspec/` | OpenSpec configuration and templates |
| `setup.sh` | Lightweight install/update script |
| `tests/` | setup.sh regression tests (dev-only, not distributed) |

## Install into a target repository

```bash
./setup.sh /path/to/target-repository            # install: add missing files only
./setup.sh --update /path/to/target-repository   # update: overwrite AgentCraft-managed files
```

The script copies agents, skills, docs (into `docs/agentcraft/`), and OpenSpec config into the
target. It copies `templates/AGENTS.md` only when the target has no `AGENTS.md`; an existing
`AGENTS.md` is left untouched. An existing `openspec/config.yaml` is preserved.

By default the script is **additive**: it adds missing files and never overwrites. With
`--update` it overwrites only the files AgentCraft itself installed — tracked per-file in
`.pi/agentcraft-manifest` — and skips locally modified or foreign same-named files with a
warning. It also writes the installed version to `.pi/agentcraft-version`. Even in update
mode, `AGENTS.md` and `openspec/config.yaml` are never overwritten. Keep customisations in
your own files rather than editing AgentCraft's files in place, so `--update` does not clobber
them.

## Verify

Run the setup.sh regression tests:

```bash
tests/run.sh
```

## Key principles

- User approval at defined checkpoints; no implementation before requirements, design, and Test plan are approved.
- Deterministic, programmatic verification over self-reported "done".
- Separate implementation, code review, and QA testing responsibilities.
- Simplicity: no backend, no databases, no orchestration runtime — only lightweight configuration assets.
