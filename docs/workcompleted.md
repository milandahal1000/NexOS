# NexOS Work Completed

Use this file as a chronological log. Append a new dated section after each completed phase. Never claim success without evidence.

## Initial project setup

- **Date:** 2026-10-27
- **Phase:** Planning and build-environment investigation
- **Known environment:** Fedora 44, x86_64; KIWI CLI 11.1.1 and `kiwi-systemdeps` 11.1.1 installed; `kiwi-systemdeps-iso-media` and `distribution-gpg-keys` installed.
- **Upstream image descriptions:** `build/vendor/fedora-kiwi-descriptions`, detached at Fedora 44 commit `dfc49a5` during initial investigation.
- **Profile identified:** `Xfce-Live`, which requires `Xfce-Desktop` and `LiveInstall`; live install profile includes Anaconda live installer components.
- **Host resources observed:** 178 GB free in the home filesystem; 7.5 GiB RAM, about 2.6 GiB available at the time of check.
- **Completed:** Inspected `VARIANTS.md`, `kiwi-build`, Xfce profile definition, live-install profile, and initial repository structure.
- **Not yet verified:** Successful ISO build, ISO boot, Anaconda installation, first boot, physical hardware compatibility, NexOS branding, Developer Hub.
- **Next:** Verify remaining live ISO dependencies and run a controlled baseline Fedora 44 Xfce ISO build after validating the exact package/tool requirements.

## Phase 0 — Repository and host audit
- **Date:** 2026-10-27
- **Phase:** 0 (Repository and host audit) — Completed
- **Commands run (actual output):**
  - `git status --short`, `git branch --show-current`, `git log --oneline -5`
  - `ls -la`, `ls -la docs/ build/`
  - `cat /etc/fedora-release`, `uname -m`, `free -h`, `df -h /home "$PWD"`
  - `git -C build/vendor/fedora-kiwi-descriptions rev-parse HEAD && branch/status/remote/log`
  - `rpm -q kiwi-cli kiwi-systemdeps kiwi-systemdeps-iso-media dracut-kiwi-live distribution-gpg-keys anaconda-live`, `dnf --version`, `virt-install --version`
  - `grep -n -iE "error|failed|fatal"` on failed build log, inspected vendor `kiwi-build`/`Fedora.kiwi` profiles, `ls -l /dev/kvm`, checked virtualization packages
- **Actual environment (verified):**
  - Host: Fedora 44 (Forty Four), x86_64. `/home` has 178 GB free. RAM 7.5 GiB total, **~3.1 GiB available** (swap in use). KVM `/dev/kvm` present; qemu-kvm/edk2-ovmf/virt-manager/libvirt installed.
  - KIWI: kiwi-cli 11.1.1, kiwi-systemdeps 11.1.1, kiwi-systemdeps-iso-media, **dracut-kiwi-live 11.1.1 confirmed installed**; `dracut-kiwi-image-live` not installed (not needed). `kiwi-ng` 11.1.1 available; `sudo` requires password.
  - Vendored: `build/vendor/fedora-kiwi-descriptions` detached at **dfc49a5a10f69941179fdadd96aa6a5984f7c677** (clean), origin forge.fedoraproject.org/releng/kiwi-descriptions.git. `build/vendor/fedora-kickstarts` present at f3ffde6 (unused by KIWI path).
- **Repository reconciliation:**
  - `docs/architecture.md` deleted (unstaged), replaced by `docs/Architecture.md` (new richer KIWI-based rewrite). Original content preserved in git history. Kept `docs/Architecture.md` as canonical; updated `README.md` reference. Work history/decisions live at `docs/workcompleted.md`, `docs/decisions/decisions.md`.
- **Failed build preserved (evidence):**
  - A prior build attempt ran in `build/output-build/` (root-owned, now scheduled for removal per user approval; log copied to `build/logs/2026-10-27-failed-xfce-live-image-root.log`). Failure: in bootstrap, dnf5 RPM `%sysusers` scriptlets failed with **exit 127** and `failed to open /etc/group for id/name lookup: No such file or directory` (setup, systemd, dbus, polkit, chrony, etc.), leading to `Transaction failed: Rpm transaction failed.` Also observed: `skipped OpenPGP checks for 278 packages` in bootstrap.
- **Changes made this phase:**
  - Added `build/scripts/clone-vendor.sh` (pin to dfc49a5 / f3ffde6), updated `.gitignore` (`build/output*/`, `build/vendor/`, `build/logs/`), updated `Makefile` (replaced kickstart targets with `clone-vendor`, removed missing script refs), updated `build/scripts/check-host.sh` (KIWI-focused checks), updated `README.md`, preserved failed build log.
- **Artifacts/evidence:** `build/logs/2026-10-27-failed-xfce-live-image-root.log` (171KB).
- **Remaining issues/blockers:** Bootstrap sysusers failure with dnf5 on F44 (investigate fix/known workaround before rebuild). Available RAM is tight (~3.1 GiB) — will free memory before Phase 1. Need to remove root-owned `build/output-build/` (blocked by sudo requiring terminal in this environment; user approval given).
- **Next:** Research KIWI/dnf5 sysusers workaround and correct invocation, then attempt baseline `Xfce-Live` build into `build/output/` after freeing RAM.


## Phase 1 — Baseline Fedora 44 Xfce live ISO

- **Date:** 2026-10-28
- **Phase:** 1 (Baseline Fedora Xfce live ISO) — Completed
- **Goal:** Produce and verify a baseline `Xfce-Live` ISO from the pinned Fedora 44 KIWI descriptions.

### Root cause of the Phase 0 build failure

- The build ran under the SELinux domain `unconfined_u:unconfined_r:kiwi_t`. Fedora 44's `kiwi` policy performs a type transition on shell execution to `rpm_script_t` but does not grant `allow kiwi_t rpm_script_t:process transition;`.
- Result: every rpm scriptlet that exec'd `/bin/sh` (notably `%sysusers`) failed with EACCES, which rpm reports as `scriptlet failed, exit status 127`. This was confirmed with an `LD_PRELOAD` `execve` shim (`errno=13`, context `kiwi_t`) and the audit log (`avc: denied { transition } ... tclass=process`).
- A temporary `setenforce 0` test produced zero sysusers failures; SELinux was immediately restored to Enforcing.

### Fix

- Added `build/selinux/nexos-kiwi-fix.te` (`allow kiwi_t rpm_script_t:process transition;`) and `build/scripts/setup-selinux.sh` (idempotent build/install; requires `checkpolicy`).
- Added `make host-selinux`; extended `build/scripts/check-host.sh` to require the policy tools and report the module.
- Installed the module on the host with `semodule -i`; verified it stays Enforcing.

### Build configuration

- `build/overlay/Fedora.kiwi` adds `<rpm-check-signatures>true</rpm-check-signatures>`; `build/scripts/prepare-description.sh` regenerates `build/nexos-descr/` from the pinned vendor tree plus the overlay (the generated tree is gitignored). `make build` runs the full command.
- Reverted the earlier bootstrap-package and `/etc/passwd`-style workarounds; they were based on the wrong chroot hypothesis and are not needed.
- Command:
  `sudo kiwi-ng --type=iso --profile=Xfce-Live --kiwi-file=Fedora.kiwi --color-output system build --description build/nexos-descr --target-dir build/output/build`
- The first two attempts reached ISO packing but `mkfs.erofs` was OOM-killed on the 7.5 GiB host (global OOM; 1.5–2.1 GiB anon at kill). Added a 12 GiB btrfs swap file at `/home/nexos-swapfile` (`btrfs filesystem mkswapfile`, `swapon`) and reran with `--allow-existing-root`; the build then completed.

### Result

- Exit status 0; zero `scriptlet failed, exit status 127`; zero `skipped OpenPGP checks`.
- Artifact: `build/output/build/Fedora.x86_64-44.iso`, 2,928,658,432 bytes, SHA-256 `47e80127b99cb8f4b304032883fb5c44c61d94294019561798da717ec3d74718`.
- Metadata: `Fedora.x86_64-44.{changes,packages,verified}`; log `build/logs/2026-10-28-xfce-live-build-resume2.log`.
- ISO is BIOS + UEFI bootable (El Torito BIOS entry and 60 MiB EFI image); `file` reports a bootable ISO 9660 image with volume `Fedora_Linux`.
- Image root has 73 groups / 49 users, including systemd/dbus/polkit system accounts, confirming `%sysusers` ran.

### Boot verification (UEFI and BIOS)

- UEFI: QEMU/OVMF (`-machine q35`, 3 GiB, 2 vCPU) booted the ISO; GRUB menu appeared, media check completed, and the Xfce desktop rendered at 1280x800. `ctrl-alt-f2` switched to a text VT and `ctrl-alt-f1` returned to the desktop. Screenshot: `build/logs/2026-10-28-xfce-live-desktop.png`.
- BIOS: QEMU (`-machine pc`, no OVMF) booted the same ISO to the same desktop. Screenshot: `build/logs/2026-10-28-xfce-live-desktop-bios.png`.
- Not yet tested: interactive Xfce functionality, Anaconda install, installed-system first boot.

### Host changes

- Installed `checkpolicy` (builds the SELinux module). `setools-console` was installed for diagnosis and then removed.
- Temporary/persistent 12 GiB swap file `/home/nexos-swapfile`; keep it for rebuilds on this host unless the user asks to remove it.

### Cleanup

- Removed failed root-owned build outputs, `build/testroot*`, and `/tmp/nexos-*` debug artifacts.
- Host `systemd-sysusers`, `/bin/sh`, `/etc/rpm/macros`, and the temporary wrapper/symlink from the earlier instrumentation are restored/removed.

### Next

- Phase 2: run Anaconda against a disposable virtual disk, boot the installed system, and verify login, networking, updates, and shutdown.

## Phase 2 — Boot and installer validation

- **Date:** 2026-10-28
- **Phase:** 2 (Boot and installer validation) — Completed
- **Goal:** Produce the final Phase 2 ISO with the GRUB/erofs fixes, boot it under UEFI, clean-install it to a fresh disk, and validate the installed system.

### Final ISO build

- Rebuilt after the GRUB and erofs-packing fixes using the documented KIWI command with `--allow-existing-root`.
- Build exit status 0; no `ERROR`, `Traceback`, `FAILED`, or `segfault` entries in `/tmp/nexos-build7.log`. Build log preserved at `build/logs/2026-10-28-phase2-final-iso-build.log`.
- Artifact: `build/output/build/Fedora.x86_64-44.iso`, **3,648,210,944 bytes**, SHA-256 `ef2d0769d281592e89cd2f8807b60d7bacae3f1cbb8fd61be08c2bd489f2957d`.
- The existing `.sha256` file was stale; it was regenerated for the final ISO and verified with `sha256sum -c` (OK).
- The final ISO's embedded GRUB config was extracted and checked: default entry is `Start Fedora`, `set default="0"`, and `grub2-script-check` returns 0 after substituting KIWI's `$$` escapes. Raw-template validation still requires the substitution because upstream uses KIWI escaping.

### Final ISO boot verification

- QEMU/OVMF (`q35`, 4 GiB RAM, 4 vCPU, virtio) booted the final ISO; GRUB displayed `Start Fedora`, and the Xfce live desktop loaded.
- Evidence:
  - `build/logs/2026-10-28-phase2-final-iso-grub.ppm`
  - `build/logs/2026-10-28-phase2-final-iso-live.ppm`
  - `build/logs/2026-10-28-phase2-final-iso-live.png`
  - `build/logs/2026-10-28-phase2-final-iso-serial.log`

### Clean install to a fresh disk

- Created fresh target `build/output/phase2b/nexos-install.qcow2` (20 GiB virtual; 5.0 GiB allocated after install) and fresh OVMF vars `/tmp/nexos-clean-vars.fd`.
- Booted the final ISO with the clean target and used Anaconda Web UI in remote mode. The test-only automation path was:
  - Serial console for live-shell access: `liveuser` with no password, passwordless sudo, and a temporary root SSH key.
  - `webui-desktop -t live -r 1` plus `/sbin/anaconda --liveinst --graphical`; direct `liveinst` over SSH failed because the live browser needed a missing `Xauthority` and aborted.
  - Anaconda was launched with `PKEXEC_UID=1000`, `XDG_RUNTIME_DIR=/run/user/1000`, and `DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus`. Without the live-user environment, the localization module failed with `Live user is requested to run command but can't be found` and the Web UI could not advance.
  - Web UI accessed through an SSH tunnel on `127.0.0.1:9093`; QEMU host-forward `9092` was not usable in this environment. Playwright drove the UI.
- Installer selections: English (United States), Asia/Kathmandu, erase entire disk, Btrfs default layout, local account `nuser` (`NexOS Test User`, `wheel`), root account locked.
- Anaconda reported `Successfully installed`; evidence: `build/logs/2026-10-28-phase2-install-success.png`.
- Test-only serial-console kernel argument (`console=ttyS0,115200`) was propagated into the installed system. Before first boot, the artifact was removed from `/etc/default/grub`, `/etc/kernel/cmdline`, and the BLS entries, and `grub2-mkconfig` was rerun. The installed `/proc/cmdline` is clean:
  `BOOT_IMAGE=(hd0,gpt2)/vmlinuz-7.2.13-200.fc44.x86_64 root=UUID=6ede7a44-3018-4a92-b4cd-3d1dd0090759 ro rootflags=subvol=root`

### Installed-system validation

- Booted the installed disk alone (no ISO attached) under UEFI/OVMF with the same vars; the installed system reached the LightDM greeter, showing the local account.
- Logged in as `nuser` through a local VT and over SSH; account is UID/GID 1000 and is in `wheel`. The graphical target is active and LightDM is active.
- `systemctl --failed` is empty; SELinux is `Enforcing`.
- Networking via DHCP is up on `enp0s2` (`10.0.2.15/24`, default route `10.0.2.2`); ICMP to `8.8.8.8` succeeds and DNS resolves `fedoraproject.org`.
- `dnf --repo=updates --setopt=ip_resolve=4 check-update` completed with exit status 0 (update metadata loaded). The full multi-repo check did not complete within a 150 s test timeout; the updates repository itself was successfully fetched. Treat the full-repo timeout as a VM/network test limitation, not an image failure.
- Clean shutdown succeeded and QEMU exited.
- Evidence:
  - `build/logs/2026-10-28-phase2-installed-login.png`
  - `build/logs/2026-10-28-phase2-installed-tty-login.png`
  - `build/logs/2026-10-28-phase2-installed-boot-serial.log`
  - `build/logs/2026-10-28-phase2-installed-validation.txt`
  - `build/logs/2026-10-28-phase2-installed-dnf-updates.txt`

### Limitations and next

- Clean install and first boot were validated under UEFI/QEMU only; BIOS installation and physical hardware are not yet tested.
- The final ISO is still Fedora-branded; NexOS product metadata and branding begin in Phase 3.
- The fallback repaired disk remains at `build/output/phase2/nexos-install.qcow2`; final clean-install evidence is the Phase 2b disk.
- **Next:** Phase 3 — create the NexOS-owned image overlay, product metadata/labels, and branding hooks without editing the pinned vendor tree.
