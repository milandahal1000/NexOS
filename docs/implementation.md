# NexOS Implementation Roadmap

**Initial target:** Fedora 44, x86_64  
**Method:** Incremental, test-driven, local builds first  
**Rule:** Do not skip a phase's acceptance criteria. Replan if Fedora 44 package/image tooling differs from expectations.

## Phase 0 — Repository and host audit

### Tasks
- Inspect repository structure, Git status, remotes, and existing documentation.
- Confirm host release and architecture.
- Verify KIWI CLI and required ISO dependencies.
- Confirm Fedora KIWI definitions are on `f44` and record the exact commit.
- Check disk space and memory.
- Review `.gitignore` and ensure build output is not accidentally committed.

### Acceptance criteria
- A written host/build-environment report exists.
- No user changes are overwritten.
- Fedora 44 upstream source is pinned and its role documented.
- Required package names are verified locally.

## Phase 1 — Baseline Fedora Xfce live ISO

### Tasks
- Determine the supported KIWI build command for the pinned Fedora 44 descriptions.
- Inspect the profile's required packages, ISO preferences, and live installer components.
- Validate the description/profile without running a full build if the available tooling supports validation.
- Build the upstream `Xfce-Live` baseline in a NexOS-owned output directory.
- Capture logs and build metadata.

### Acceptance criteria
- Build exits successfully.
- ISO artifact exists and is non-empty.
- Record exact artifact name, size, SHA-256, source commit, and command.
- If the build fails, record the actual error and fix it before continuing.

### Status
- **Completed:** 2026-10-28. `Fedora.x86_64-44.iso` (2,928,658,432 bytes,
  SHA-256 `47e80127b99cb8f4b304032883fb5c44c61d94294019561798da717ec3d74718`)
  built from `dfc49a5` with a 12 GiB swap file added to the build host.
- Fixed a Fedora 44 SELinux policy gap (`kiwi_t` → `rpm_script_t`
  transition) that made rpm `%sysusers` scriptlets exit 127 (D-010).
- Enabled RPM GPG signature verification (D-011) and kept upstream
  erofs + lzma live-root packing (D-012). See `workcompleted.md`.

## Phase 2 — Boot and installer validation

### Tasks
- Boot ISO in a UEFI virtual machine.
- Verify Xfce live session starts.
- Check network, keyboard, display, terminal, file manager, and browser if present.
- Launch Anaconda and complete a test installation to a disposable virtual disk.
- Boot installed system and verify local user login, networking, updates, and shutdown.

### Acceptance criteria
- Evidence is recorded for every test.
- Installer and first boot both succeed in a VM.
- Any limitation is documented.
- Do not claim physical hardware compatibility from VM testing alone.

### Status
- **Completed:** 2026-10-28. The final Phase 2 ISO boots to the Xfce live
  desktop under UEFI (OVMF) in QEMU; the earlier Phase 1 baseline also
  booted under BIOS. A clean Anaconda install to a fresh UEFI disk
  completed, and the installed system reached LightDM with local login,
  networking, DNS, enforcing SELinux, and a passing `updates` repository
  metadata check.
- **Limitation:** Final-ISO boot and installation/first boot are validated
  under UEFI/QEMU only; BIOS installation and physical hardware are not
  yet tested. The full multi-repo `dnf check-update` timed out in the test
  VM, while the `updates` repository check succeeded. Details and evidence
  are recorded in `workcompleted.md`.

## Phase 3 — NexOS-owned image configuration

### Tasks
- Create a NexOS-owned description or overlay without editing vendor files directly.
- Keep Fedora 44 release settings and profile inheritance correct.
- Add NexOS product metadata and branding where supported.
- Set NexOS ISO volume/application labels using supported KIWI configuration.
- Add build scripts with argument validation and clear errors.
- Add build instructions and checksums to documentation.

### Acceptance criteria
- NexOS configuration is separate from vendor source.
- The image still builds and boots.
- Branding does not misrepresent NexOS as an official Fedora edition.
- Upstream revision and custom patches are recorded.

### Status
- **Completed:** 2026-10-28. The NexOS overlay now sets the image name and
  GRUB display name to `NexOS`, records NexOS project metadata, and uses
  `NexOS Project` / `NexOS_Live` for the ISO publisher, volume ID, and
  application ID. The generated GRUB menu offers `Start NexOS`, and the
  live root uses `root=live:CDLABEL=NexOS_Live`.
- `build/scripts/build-iso.sh` now validates options and required inputs,
  refreshes `build/nexos-descr/`, builds through KIWI, and regenerates the
  artifact `.sha256`. `make build` delegates to it.
- Artifact: `build/output/phase3/NexOS.x86_64-44.iso`, 3,649,394,688
  bytes, SHA-256
  `d2def470509374dcb045622edc1af8e17ab91f5dfae821f0a70bdb3e716b1d47`.
  The ISO booted to the Xfce live desktop under UEFI/QEMU.
- **Limitation:** The live system still uses Fedora's `/etc/os-release` and
  desktop artwork; those identity/branding surfaces move to Phase 4. The
  Phase 3 ISO was boot-tested, not reinstalled. BIOS and physical hardware
  remain untested. Details and evidence are in `workcompleted.md`.

## Phase 4 — Desktop branding and defaults

### Tasks
- Add licensed NexOS wallpaper, icons, theme configuration, and desktop defaults.
- Configure Xfce panel and launcher.
- Evaluate Plank package availability and session stability; add only if reliable.
- Provide light and dark themes with purple accent.
- Avoid duplicate panels/docks and inaccessible launch methods.

### Acceptance criteria
- Settings persist across login/reboot.
- No autostart loop or duplicate panel/dock.
- Keyboard-accessible application launching remains available.
- Licenses/attributions for assets are documented.

## Phase 5 — Core developer tools

### Tasks
- Create a reviewed package manifest.
- Add Git, Python 3 plus pip/venv support, Node.js/npm, OpenJDK, and Firefox as appropriate.
- Evaluate the correct Visual Studio Code distribution/source and redistribution/licensing implications.
- Separate required packages from optional recommendations.
- Test installation, launch, version reporting, and updates.

### Acceptance criteria
- Every package is available from a documented source.
- The image builds and boots after adding the tools.
- Versions and package origins are recorded.
- Image size and memory impact are measured.

## Phase 6 — Performance and reliability

### Tasks
- Measure idle RAM, boot time, ISO size, and installed disk usage.
- Test network, audio, graphics, suspend/resume, and external display where possible.
- Evaluate a 4 GB RAM workload as a target, not a promise.
- Remove only demonstrably unnecessary packages/services.
- Preserve Fedora security controls.

### Acceptance criteria
- Results include test hardware/VM settings and measurement method.
- No optimization weakens security without an approved decision.
- Performance claims are evidence-based.

## Phase 7 — Developer Hub design and service layer

### Tasks
- Confirm Python + GTK 4/PyGObject compatibility and package availability.
- Design a structured package catalog with stable IDs and source metadata.
- Implement a shared service layer for GUI and CLI.
- Define supported package backend operations and privilege authorization.
- Create unit tests before connecting UI actions to package changes.

### Acceptance criteria
- Catalog cannot express arbitrary shell commands.
- Invalid package IDs are rejected.
- Authorization denial, cancellation, and backend failures are handled.
- Tests cover core service behavior.

## Phase 8 — Developer Hub GUI and CLI

### Tasks
- Build native GTK 4 GUI and CLI on the shared service layer.
- Display installed status, package source, and change summary.
- Show progress and useful errors.
- Support browsing and status checks offline.
- Package and integrate as an optional application.

### Acceptance criteria
- GUI and CLI share the same service logic.
- Privileged actions use the approved authorization path.
- Tests pass and installation/removal behavior is documented.
- Base desktop remains usable if Developer Hub is unavailable.

## Phase 9 — Updates, packaging, and release process

### Tasks
- Define how NexOS custom packages/configuration receive updates.
- Keep normal Fedora updates working.
- Decide whether custom RPMs or a repository are necessary; do not introduce one without a clear need.
- Add version metadata and a release checklist.
- Generate checksums and publish build instructions.
- Document recovery and known issues.

### Acceptance criteria
- Update behavior is tested.
- Release artifact and checksum match.
- Licensing and third-party sources are reviewed.
- All docs reflect actual tested features.

## Phase 10 — Release candidate

### Tasks
- Rebuild from documented inputs.
- Run the complete VM test suite.
- Run physical hardware smoke tests where available.
- Review all logs, package sources, licenses, and documentation.
- Update all required status/decision files.

### Acceptance criteria
- ISO boots and installs in the tested environments.
- All critical acceptance checks pass.
- Known limitations are published.
- `README.md`, `workcompleted.md`, and `decisions.md` are current.

## Work protocol for OpenCode

At the beginning of a phase:
1. Read the project rules and current status/decision logs.
2. Check `git status` and inspect relevant files.
3. State the phase goal and acceptance criteria.
4. Make only the changes needed for that phase.

At the end of a phase:
1. Run the relevant checks and capture real output.
2. Update `README.md`.
3. Append to `workcompleted.md`.
4. Update `decisions.md` if a decision was made or changed.
5. Update this roadmap if scope/status changes.
6. Summarize outcomes and propose the next phase; do not silently continue into risky or expensive work.
