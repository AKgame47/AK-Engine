# Contributing to AK Engine

Read [Architecture](ARCHITECTURE.md), [Status](STATUS.md), [Licence Audit](LICENSE-AUDIT.md), and [Roadmap](ROADMAP.md). Ask the area owner before overlapping runtime, CI, export, or Core changes. The current work split leaves those areas and main-branch review and merging with Instinct.

1. Start a task-named branch from the current main, for example `git switch -c docs/install-guide`. Never push directly to main.
2. Keep commits small and focused. Do not bundle generated builds, local engine caches, or credentials. Check `git status --short` and `git diff --check`.
3. Validate through the right entry point. Use the [Core setup](GETTING-STARTED.md#1-clone-and-test-ak-core) for a Core change, then try the actual editor, sample, or export where relevant. Report the OS, engine version, renderer, command and result. State any missing target coverage and distinguish local checks from CI.
4. Document the origin and licence of assets, code, and generated data. Keep upstream headers and notices. Use original or verified compatible material; no GPL source inside the MIT runtime/editor. External Blender authoring does not waive an asset’s own licence. Do not rely on the word “free” as permission to redistribute.
5. Request review on the branch/PR. Tell reviewers what changed, how it was verified, and what is intentionally out of scope. Do not claim unbuilt features, CI results, or performance that has not been measured. Review and merge are performed by the maintainer/owner.

This page does not grant permission to change another contributor's branch or to trigger a workflow that writes to main.
