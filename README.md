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
| `AGENTS.md` | Project instructions loaded by the coding agent |
| `agents/` | Subagent definitions (distributed to `.pi/agents`) |
| `skills/` | Engineering skills (distributed to `.pi/skills`) |
| `docs/` | Workflow, orchestrator, and quality-gate documentation |
| `openspec/` | OpenSpec configuration and templates |
| `setup.sh` | Lightweight install/update script |

## Install into a target repository

```bash
./setup.sh /path/to/target-repository   # default: current directory
```

The script copies agents, skills, docs, and OpenSpec config into the target, preserving any
existing `AGENTS.md` and `openspec/config.yaml`.

## Key principles

- User approval at defined checkpoints; no implementation before requirements, design, and Test plan are approved.
- Deterministic, programmatic verification over self-reported "done".
- Separate implementation, code review, and QA testing responsibilities.
- Simplicity: no backend, no databases, no orchestration runtime — only lightweight configuration assets.
