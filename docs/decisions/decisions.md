# NexOS Decision Log

Record decisions that affect architecture, dependencies, security, release process, or user experience. Add new entries; do not erase history. If a decision changes, mark the old entry superseded and explain why.

## D-001 — Fedora base and initial architecture

- **Date:** 2026-10-27
- **Status:** Accepted
- **Decision:** Use Fedora Linux as the base, target x86_64 first, and evaluate ARM64 later.
- **Rationale:** User-selected project direction; reuse Fedora packaging and update ecosystem.
- **Consequences:** Build definitions, package choices, and test matrix initially target Fedora 44 x86_64.

## D-002 — Xfce desktop

- **Date:** 2026-10-27
- **Status:** Accepted
- **Decision:** Use Xfce as the initial desktop environment.
- **Rationale:** Fits the lightweight developer-workstation goal.
- **Consequences:** Desktop defaults and branding must be tested in Xfce; avoid introducing multiple desktops in the first milestone.

## D-003 — Start with Fedora 44 Xfce Live baseline

- **Date:** 2026-10-27
- **Status:** Accepted; baseline build, ISO boot, install, and first boot validated 2026-10-28
- **Decision:** First attempt a baseline image using the Fedora 44 KIWI descriptions and `Xfce-Live` profile before adding NexOS-specific customizations.
- **Rationale:** Separate upstream build/tooling problems from NexOS customization bugs.
- **Consequences:** A successful build alone is not sufficient; boot and installer behavior must be tested before creating the NexOS overlay.

## D-004 — Keep upstream image descriptions separate

- **Date:** 2026-10-27
- **Status:** Accepted
- **Decision:** Treat `build/vendor/fedora-kiwi-descriptions/` as pinned third-party source and keep NexOS customizations in NexOS-owned configuration/overlays.
- **Rationale:** Easier updates, clearer diffs, and reproducible builds.
- **Consequences:** Do not routinely edit vendor files directly. Record the exact upstream commit and any intentional patches.

## D-005 — Developer Hub technology direction

- **Date:** 2026-10-27
- **Status:** Proposed; compatibility/security review required
- **Decision:** Evaluate Python + GTK 4/PyGObject for the native GUI and CLI, using a shared service layer and DNF/RPM backend.
- **Rationale:** Keep the initial application stack maintainable and native to Fedora.
- **Consequences:** Must verify Fedora 44 package availability and use a supported privilege authorization mechanism. Catalog metadata must never execute arbitrary shell commands.

## D-006 — Local accounts and no required cloud account

- **Date:** 2026-10-27
- **Status:** Accepted
- **Decision:** NexOS must support local accounts and must not require a NexOS cloud account for normal desktop use.
- **Rationale:** Offline-friendly, user-controlled workstation experience.
- **Consequences:** No mandatory cloud authentication or telemetry.

## D-007 — Vendored upstream repos pinned via clone script

- **Date:** 2026-10-27
- **Status:** Accepted
- **Decision:** Keep `build/vendor/` untracked and gitignored; pin `fedora-kiwi-descriptions` at `dfc49a5a10f69941179fdadd96aa6a5984f7c677` and `fedora-kickstarts` at `f3ffde6a446f7ff89d8ca3fb2417d9e4115ddd1f` via `build/scripts/clone-vendor.sh`. No git submodules.
- **Rationale:** Avoids detached-submodule friction, keeps vendored code out of NexOS history while ensuring reproducible pins.
- **Consequences:** Builds require running `make clone-vendor` (or the script); vendor updates are explicit and documented.

## D-008 — Canonical architecture document

- **Date:** 2026-10-27
- **Status:** Accepted
- **Decision:** `docs/Architecture.md` is the canonical architecture document (richer, KIWI-based). `docs/architecture.md` was removed/replaced; original content is preserved in git history.
- **Rationale:** Aligns with the actual KIWI build approach discovered during audit.
- **Consequences:** References updated to `docs/Architecture.md`; ensure docs stay in sync with implementation.

## D-009 — Remove failed root-owned build artifacts

- **Date:** 2026-10-27
- **Status:** Accepted
- **Decision:** Remove the failed root-owned `build/output-build/` after preserving its log in `build/logs/`. New builds go in `build/output/`.
- **Rationale:** Frees space and avoids confusion; evidence preserved.
- **Consequences:** Removal may require `sudo`/chown by the user in some environments.


## D-010 — Local SELinux policy fix for KIWI rpm scriptlets

- **Date:** 2026-10-28
- **Status:** Accepted
- **Decision:** Keep SELinux Enforcing on the build host and install a small local policy module, `nexos-kiwi-fix`, that grants `allow kiwi_t rpm_script_t:process transition;`. Track the policy source in `build/selinux/` and install it with `make host-selinux`.
- **Rationale:** Fedora 44's `kiwi` policy transitions shell execution from `kiwi_t` to `rpm_script_t` without allowing the transition. The kernel therefore returns EACCES when rpm scriptlets such as `%sysusers` exec `/bin/sh`, and rpm reports `scriptlet failed, exit status 127`. Disabling SELinux would hide the policy gap and weaken the build host.
- **Consequences:** Enforcing hosts must install the module before building (the host check reports it). The module is additive and can be removed with `semodule -r nexos-kiwi-fix`. Revisit when upstream `kiwi` policy is fixed.

## D-011 — Verify RPM GPG signatures during image builds

- **Date:** 2026-10-28
- **Status:** Accepted
- **Decision:** Set `<rpm-check-signatures>true</rpm-check-signatures>` in the image preferences instead of relying on KIWI's default `gpgcheck=0`.
- **Rationale:** Package provenance is part of the build's supply-chain integrity. Repository definitions already import Fedora's GPG keys.
- **Consequences:** Builds fail on unsigned or badly signed packages. Do not weaken this to make a build pass; fix the repository or key configuration instead.

## D-012 — Keep upstream erofs + lzma live root and document host memory needs

- **Date:** 2026-10-28
- **Status:** Accepted; erofs fragment options superseded by D-014
- **Decision:** Keep Fedora's upstream live-root format (`erofs`, `erofscompression="lzma,level=6"`, `fscreateoptions="-Efragments -C 1048576"`) rather than switching to a lighter format to fit the current host. Build hosts need enough RAM/swap for packing; a 12 GiB swap file was used on the 7.5 GiB baseline host.
- **Rationale:** Staying with upstream image settings keeps the baseline comparable to Fedora's own live media and avoids a product-level format decision made only to work around local memory pressure.
- **Consequences:** `mkfs.erofs` is OOM-killed on low-memory hosts without swap. Documented in `README.md`; revisit if build hosts cannot meet the requirement. D-014 later disabled erofs fragments because `mkfs.erofs` 1.9.4 crashed during packing; erofs + lzma remains.

## D-013 — Clean KIWI-generated `blsdir` from the live image GRUB environment

- **Date:** 2026-10-28
- **Status:** Accepted
- **Decision:** Keep the vendored image `config.sh` unchanged and add a NexOS-owned `images.sh` hook (`build/overlay/images.sh`). The hook runs after `config.sh` and before image creation, and executes `grub2-editenv /boot/grub2/grubenv unset blsdir` inside the image root.
- **Rationale:** KIWI's in-chroot `grub2-mkconfig` wrote `blsdir=/home/<builder>/.../build/image-root/boot/loader/entries` into the live image's `grubenv`. Anaconda copies that file into the installed system, where GRUB's `blscfg` looks for BLS entries at the stale build-host path, finds none, and offers only “UEFI Firmware Settings”. Selecting that entry enters firmware setup and loops back to the boot menu. Removing `blsdir` restores the default `${root}/boot/loader/entries` lookup; the repaired installed system then booted to LightDM and Xfce normally.
- **Consequences:** `build/scripts/prepare-description.sh` now requires `build/overlay/images.sh`; the file is copied into the generated description and imported by KIWI as the pre-create script. Re-test installed-system first boot after every vendor or KIWI update until upstream stops writing a host-path `blsdir`.

## D-014 — Disable erofs fragments to avoid mkfs.erofs 1.9.4 crash

- **Date:** 2026-10-28
- **Status:** Accepted
- **Decision:** Override the vendor `components/liveinstall.xml` in `build/overlay/` and remove `fscreateoptions="-Efragments -C 1048576"`. Keep erofs and `erofscompression="lzma,level=6"`; only fragment packing is disabled.
- **Rationale:** Two consecutive full builds with the upstream fragment options ended in `mkfs.erofs[PID]: segfault at ... in mkfs.erofs[...]` at 17:01:57 and 17:15:48. The failed builds then reported `KiwiCommandError: mkfs.erofs: failed to commit fragment ...: [Error 5] Input/output error`. A manual run of the same image root with `-z lzma,level=6` and no `-Efragments` completed successfully, producing a 3.1 GiB erofs image.
- **Consequences:** The live root keeps upstream erofs+lzma compression but does not use fragments; ISO size may grow slightly (observed test image 3.1 GiB vs. ~2.8 GiB with fragments). Re-test fragment packing after an `erofs-utils` update. Keep `-C 1048576` out while fragments are disabled.
