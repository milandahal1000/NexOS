# NexOS Repository Rules

These rules apply to contributors and AI coding agents, including OpenCode.

## 1. Work safely

1. Inspect the current repository before making changes.
2. Read `README.md`, `docs/design.md`, `docs/Architecture.md`, `docs/implementation.md`, `docs/rules.md`, `workcompleted.md`, and `decisions.md` before starting a new phase.
3. Do not overwrite or delete existing user work without explicit approval.
4. Do not run destructive commands such as `rm -rf`, `git reset --hard`, `git clean -fdx`, or broad ownership/permission changes unless the user explicitly approves the exact action.
5. Do not change the Git remote, rewrite history, force-push, or commit/push without explicit permission.
6. Do not run privileged commands or make system-wide changes without explaining the reason and asking the user to run/approve them when appropriate.
7. Never expose, request, or commit passwords, tokens, SSH private keys, signing keys, or other secrets.

## 2. Make incremental changes

- Work in small, reviewable phases.
- Before each phase, state the goal, files likely to change, and acceptance checks.
- Inspect actual command output before deciding the next action.
- Do not assume commands succeeded.
- After changes, run relevant tests and show the result.
- If a command fails, stop and diagnose the failure instead of piling on unrelated changes.
- Do not build the entire distribution until the current build configuration has been validated.
- Do not install unverified packages or add repositories speculatively.

## 3. Fedora and KIWI rules

- Target Fedora 44 x86_64 initially.
- Use the Fedora 44 KIWI description branch, not Rawhide, for the initial baseline.
- Record the exact upstream commit used.
- Treat `build/vendor/fedora-kiwi-descriptions/` as third-party upstream source.
- Do not make routine NexOS edits directly in the vendor checkout.
- Verify package availability using Fedora tools such as `dnf info`, `dnf repoquery`, and `rpm -q`.
- Do not assume a package name is correct just because it appears in an old tutorial.
- Preserve Fedora's installer and security behavior unless an approved requirement says otherwise.
- Never describe an ISO as bootable, installable, or release-ready without evidence from tests.

## 4. Security rules

- No arbitrary shell execution from a package catalog or downloaded metadata.
- No hidden telemetry, analytics, cloud account requirement, or network call without a documented user-facing purpose.
- Use supported Fedora privilege authorization for package installation.
- Validate all external input.
- Do not disable SELinux, firewalld, signature verification, or other security protections as a shortcut.
- Do not download or execute remote scripts as part of normal setup.
- Use official or well-established package sources and document third-party sources.

## 5. Code quality

- Prefer clear, boring, maintainable code over clever abstractions.
- Keep functions and modules focused.
- Add tests for nontrivial logic and security-sensitive behavior.
- Use consistent naming and formatting.
- Add comments for reasoning and constraints, not obvious syntax.
- Avoid adding dependencies unless the benefit and maintenance cost are justified.
- Do not add empty placeholder implementations and claim the feature is complete.
- Handle failures with actionable messages.

## 6. Documentation is mandatory

After **every completed phase**, update all applicable files:
- `README.md`: current project state, prerequisites, verified setup/build/run commands, implemented features, and limitations.
- `workcompleted.md`: date, phase, changes made, commands/tests run, results, and outstanding issues.
- `decisions.md`: new or changed architectural/technical decisions, alternatives considered, rationale, and consequences.

Also update `docs/implementation.md` when the roadmap or acceptance criteria change. Keep documentation truthful and aligned with the repository. Do not mark a task complete if it has not been tested.

## 7. Git hygiene

- Check `git status` before and after a phase.
- Do not commit generated ISOs, build caches, credentials, or machine-specific output by default.
- Keep `.gitignore` aligned with generated build artifacts.
- Do not commit unless asked.
- Never rewrite the user's commit history.

## 8. Completion report

At the end of every phase, report:
1. What changed.
2. Files created/modified.
3. Commands/tests run and their actual outcomes.
4. Known problems or unverified assumptions.
5. Documentation files updated.
6. The exact next recommended step.

If blocked, report the blocker and ask for only the information required to resolve it.
