# AgentCraft — Project Instructions

## 1. Project Overview

AgentCraft is an engineering methodology for AI-assisted software development.

It provides reusable engineering assets for AI coding agents:
- Development workflow and engineering principles.
- Agent and subagent definitions.
- Engineering Skills.
- Quality gates and verification rules.
- Platform configuration and templates.

AgentCraft is distributed into target repositories using a lightweight setup/update script.

Its goal is to make AI-assisted software development structured, predictable, and aligned with established engineering practices.

## 2. Technology Stack

AgentCraft is built primarily around the following tools.

### Pi Coding Agent

Primary AI coding platform.

https://pi.dev/

### pi-subagents

Pi extension used to provide specialized subagents.

https://pi.dev/packages/pi-subagents

AgentCraft defines agent roles, responsibilities, instructions, and capabilities. The extension provides the subagent execution and delegation mechanism.

Do not implement a custom subagent runtime.

### OpenSpec

An integral part of the AgentCraft development workflow.

https://github.com/Fission-AI/OpenSpec

https://openspec.dev/docs

OpenSpec is used to manage change specifications and engineering artifacts, including Proposals, Specs, Design, and Tasks.

AgentCraft defines how these artifacts are created, reviewed, and approved within the development workflow.

## 3. Project Structure

AgentCraft consists of:

- **Methodology** — workflow, engineering principles, responsibilities, and quality gates.
- **Agents** — specialized agent and subagent definitions.
- **Skills** — reusable engineering knowledge and practical guidance.
- **Platform configuration** — Pi and extension configuration.
- **OpenSpec configuration** — instructions and templates.
- **Setup script** — installation and updating of assets in target repositories.
- **Templates** — generic assets distributed into target repositories (e.g., `templates/AGENTS.md`).
- **Documentation** — project and workflow documentation.

Use the established Agent Skills specification. Do not invent a custom Skills format.

Keep the setup script lightweight and focused exclusively on distributing AgentCraft assets.

## 4. Development Workflow

The agreed workflow consists of eight stages:

1. **Preparation** — task and working environment preparation.
2. **Analyst** — requirements analysis and user approval.
3. **Architect** — solution design and OpenSpec artifacts preparation.
4. **QA Planning** — independent solution assessment and QA plan preparation.
5. **Developer** — implementation and primary development checks.
6. **Reviewer** — independent code review.
7. **QA Testing** — actual verification of the implementation.
8. **Finalization and Pull Request** — final checks, reporting, and PR creation.

The workflow includes feedback loops for corrections and requires user approval at defined checkpoints.

Detailed workflow rules and stage transitions are maintained in `docs/workflow.md`.

The Orchestrator role (the leading Pi agent that coordinates the stages) and stage-by-stage delegation rules are defined in `docs/orchestrator.md`.

## 5. Quality Assurance

Prefer deterministic, programmatic verification over relying on AI agents to evaluate their own work.

Use automated tests, static analysis, linters, schema validation, and other executable checks wherever practical.

AI-based engineering judgment and human approval are used where properties cannot be reliably verified by code.

Keep implementation, code review, and QA testing as separate responsibilities.

Quality Gates must define explicit, verifiable conditions for workflow transitions. An agent's declaration that its work is complete is not sufficient proof of quality.

## 6. Working Principles

- **User approval:** Significant methodology and architecture decisions require explicit approval.
- **Simplicity:** Prefer the simplest solution that meets the requirements.
- **Incremental development:** Make changes in small, reviewable steps.
- **Clear responsibilities:** Every agent must have a defined scope and expected output.
- **Traceability:** Maintain consistency between requirements, design, implementation, and verification.
- **Independent verification:** Separate implementation from review and testing.
- **No premature complexity:** Do not introduce abstractions or infrastructure without a demonstrated need.
- **Consistent documentation:** Keep related instructions and configuration aligned.

## 7. Scope Boundaries

AgentCraft is a methodology and a collection of reusable configuration assets, not a standalone software platform.

Do not introduce:
- Backend applications or services.
- Databases.
- Workflow orchestration engines.
- Custom agent execution or delegation runtimes.
- Heavy executable infrastructure.
- Premature abstractions for supporting other AI coding platforms.

Pi and its extensions provide agent execution capabilities. OpenSpec provides specification management.

The only planned executable component is the lightweight setup/update script.

Pi is the primary target platform. Supporting other platforms is not an initial goal.

## 8. Collaboration and Development

The user owns the methodology and makes final decisions about its direction.

Before implementing significant changes:
- Review the existing documentation and repository structure.
- Discuss unresolved methodological decisions.
- Explain relevant trade-offs.
- Do not silently change agreed responsibilities or workflow stages.
- Do not implement speculative features without approval.

Prefer updating existing assets over creating duplicate instructions.

Keep all changes consistent with the agreed scope and principles of AgentCraft.