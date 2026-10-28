# NexOS

NexOS is an independent, Fedora-based Linux distribution built for developers. It combines the reliability and security of Fedora with a lightweight Xfce desktop, a reproducible image build, and a focused path to a ready-to-use development workstation.

> **Status:** Early development. The Phase 3 image configuration is complete and testable in a VM, but NexOS is not release-ready. The current ISO identifies itself as NexOS in the image and boot labels, while the live desktop and `/etc/os-release` remain Fedora-branded; desktop branding and the curated developer toolset are planned for later phases.

## Why NexOS exists

Fedora is an excellent general-purpose base, but a fresh install still leaves a developer to assemble the same environment by hand: desktop defaults, terminal tools, language runtimes, editors, and a package workflow. NexOS aims to remove that repetitive setup while keeping Fedora's package ecosystem, security model, and update path.

The project is deliberately built around a few ideas:

- **Developer-first:** provide a practical starting point instead of a generic desktop install.
- **Lightweight:** use Xfce rather than a heavier desktop stack.
- **Local-first:** no mandatory cloud account, telemetry, or online sign-in for normal desktop use.
- **Reproducible:** build the ISO from a pinned Fedora description with a small, auditable NexOS overlay.
- **Transparent:** explain package changes and privileged actions instead of hiding them.
- **Fedora-compatible:** reuse Fedora packages, repositories, Anaconda, DNF, and SELinux rather than inventing a parallel platform.

NexOS is not an official Fedora edition and is not endorsed by or affiliated with the Fedora Project.

## What you get today

The current Phase 3 test ISO is a **Fedora 44 Xfce baseline with NexOS-owned image metadata, ISO labels, and build fixes**. It is the foundation for the final NexOS image, not yet the complete developer workstation.

### Included in the current test ISO

| Component | Current state |
| --- | --- |
| Base system | Fedora 44, x86_64 (`/etc/os-release` still identifies as Fedora in Phase 3) |
| Image identity | NexOS image name and GRUB title; ISO publisher `NexOS Project`; volume/application ID `NexOS_Live` |
| Desktop | Xfce 4.20: window manager, panel, desktop, Thunar, terminal, Mousepad, Ristretto |
| Display manager | LightDM login screen |
| Browser | Firefox |
| Installer | Anaconda live installer with local-account creation |
| Package management | DNF5 and RPM |
| Networking | NetworkManager; DHCP, DNS, and outbound connectivity verified in the test VM |
| Security | SELinux Enforcing; RPM GPG signature checks enabled during the build |
| Runtime | Python 3 system runtime (used by Fedora and Anaconda) |
| Accounts | Local user account; no required cloud sign-in |

The current ISO does **not** yet include a curated Git/Node.js/OpenJDK/VS Code toolchain, NexOS desktop branding (wallpaper, themes, or `os-release` identity), Plank, or the Developer Hub.

### Planned for the first NexOS release

These are roadmap items, not current claims:

- Git, Python 3 with `pip` and virtual environments, Node.js/npm, and OpenJDK.
- Visual Studio Code from an appropriate official source, subject to licensing and redistribution review.
- NexOS light and dark themes, purple accent, wallpaper, and desktop defaults.
- Plank only if it is reliable in the Xfce session.
- The optional Developer Hub GUI and CLI for discovering and installing developer tools.
- NexOS branding for the installer, login screen, and system information where supported without breaking Anaconda.

## Requirements

### Running and installing NexOS

NexOS currently targets **64-bit x86_64 PCs**. It does not claim to run on every device; broad hardware support requires testing on real hardware, which has not happened yet.

| Requirement | Current status |
| --- | --- |
| CPU | x86_64 |
| Firmware | UEFI validated for the final Phase 2 and Phase 3 ISOs; BIOS boot was validated only for the Phase 1 ISO |
| RAM | 4 GiB target; the Phase 2 and Phase 3 VMs used 4 GiB. A minimum has not been established |
| Storage | 20 GiB virtual disk used for the clean install; plan additional space for development tools |
| Display | 1280x800 tested in QEMU; other resolutions are not yet validated |
| Graphics | Basic virtual graphics tested; physical GPUs are not yet validated |
| Network | Not required for the live desktop; required for updates and optional tool installs |
| Secure Boot | Not yet validated |
| Architecture | x86_64 only; ARM64 is a future goal |

Physical hardware, Wi-Fi, audio, suspend/resume, external displays, and Secure Boot still need testing. Until then, use a VM or disposable disk for evaluation. Installation erases the selected disk.

### Building the ISO

Build host: Fedora 44 x86_64 with `sudo` access.

```sh
sudo dnf install kiwi-cli kiwi-systemdeps kiwi-systemdeps-iso-media \
    dracut-kiwi-live distribution-gpg-keys checkpolicy
make clone-vendor     # fetch pinned upstream descriptions (once)
make host-selinux     # install the nexos-kiwi-fix SELinux module (once)
make host-check
make build
```

Artifacts are written to `build/output/build/` by default (`NexOS.x86_64-44.iso` plus checksum, package, and verification metadata). The Phase 3 test artifact is in `build/output/phase3/` and is approximately 3.4 GiB.

```sh
# Optional: build into a separate directory or resume an interrupted build.
make build ISO_DIR=build/output/phase3
make build BUILD_ARGS=--allow-existing-root
```

`build/scripts/build-iso.sh` validates its arguments and required inputs, refreshes `build/nexos-descr/`, and writes a matching `.sha256` file after the build. Verify a local artifact with:

```sh
sha256sum -c build/output/phase3/NexOS.x86_64-44.iso.sha256
```

Notes:

- `build/nexos-descr/` is generated from the pinned vendor tree plus `build/overlay/`; do not edit it directly.
- Keep SELinux Enforcing. D-010 documents the Fedora `kiwi_t` policy gap and the local module that fixes `%sysusers` scriptlets.
- The live root uses erofs + lzma without fragments (D-014). Packing it is memory-hungry; on a 7.5 GiB host, add swap (12 GiB was used during the baseline build) or `mkfs.erofs` will be OOM-killed.
- RPM GPG signature verification is enabled via `<rpm-check-signatures>true</rpm-check-signatures>` (D-011).

No public release artifact has been published yet; build from source or test the local Phase 3 artifact.

## Screenshots

These screenshots are from the Phase 2 and Phase 3 QEMU test environments. The Phase 3 boot menu shows the NexOS image identity. The live desktop still shows Fedora branding because Phase 3 only changes image identity and ISO/boot labels; desktop branding begins in Phase 4.

| Phase 3 boot menu | Phase 3 live desktop | Phase 2 installed-system login |
| --- | --- | --- |
| ![Phase 3 NexOS boot menu](assets/screenshots/phase3-grub-menu.png) | ![Phase 3 NexOS live desktop](assets/screenshots/phase3-live-desktop.png) | ![Phase 2 installed-system login](assets/screenshots/phase2-installed-login.png) |

## Architecture diagrams

### Build and delivery pipeline

```mermaid
flowchart LR
    A[Pinned Fedora 44<br/>KIWI descriptions] --> C[KIWI image build]
    B[NexOS overlay<br/>metadata, labels, and build fixes] --> C
    C --> D[NexOS live ISO<br/>NexOS metadata, Fedora 44 base]
    D --> E[UEFI/BIOS boot tests]
    D --> F[Anaconda installer]
    F --> G[Installed NexOS system]
    G --> H[DNF/RPM updates]
    G -. planned .-> I[Developer Hub]
```

### User install flow

```mermaid
flowchart TD
    A[Boot the NexOS live ISO] --> B[Xfce live desktop]
    B --> C[Launch Anaconda]
    C --> D[Select disk, timezone, and local account]
    D --> E[Install to disk]
    E --> F[First boot]
    F --> G[LightDM login]
    G --> H[Desktop and Fedora updates]
```

## Project status

NexOS is in early development. Phase 3 is complete: the image builds as `NexOS.x86_64-44.iso`, its GRUB menu offers `Start NexOS`, and the ISO uses the `NexOS_Live` volume/application ID and `NexOS Project` publisher. The Phase 3 ISO booted to the Xfce live desktop under UEFI in QEMU on 2026-10-28.

The live system still uses Fedora's `/etc/os-release` and desktop artwork, so NexOS does not yet present a fully branded desktop. The next phase is desktop branding and defaults; BIOS installation and physical hardware remain untested.

Features and hardware compatibility will be verified through testing; they should not be considered complete until documented and tested.

## Project goals

- Fedora-based operating system
- Lightweight Xfce desktop with NexOS branding
- Light and dark themes with a purple accent
- Guided graphical installation
- Core development tools available out of the box
- Developer Hub with a graphical interface and CLI
- Reproducible ISO builds
- Local user accounts without mandatory cloud sign-in

## Initial target

- Architecture: x86_64
- Base: Fedora 44
- Desktop: Xfce
- Dock: Plank, if reliable
- Package management: DNF and RPM
- Build host: Fedora Linux

ARM64 support is a future goal and is not part of the initial release.

## Repository layout

- `build/` — ISO build configuration and scripts
- `desktop/` — Xfce configuration, themes, and branding
- `apps/` — NexOS applications
- `packaging/` — application packaging
- `config/` — system defaults and configuration
- `docs/` — architecture, setup, and development documentation
- `tests/` — build, ISO, VM, and hardware tests
- `assets/` — logos, screenshots, and brand assets

## Development

See [docs/Architecture.md](docs/Architecture.md) for the architecture. The detailed logs and work history are tracked in [docs/workcompleted.md](docs/workcompleted.md) and decisions in [docs/decisions/decisions.md](docs/decisions/decisions.md). The implementation roadmap is in [docs/implementation.md](docs/implementation.md).

## Contributing

Keep changes small, test them locally, and document any important architectural or security decisions.
