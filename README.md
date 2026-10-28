# NexOS

NexOS is a Fedora-based Linux distribution designed for developers.
It aims to combine a lightweight desktop, useful development tools,
and a clean, modern user experience.

## Project goals

- Fedora-based operating system
- Lightweight XFCE desktop with NexOS branding
- Light and dark themes with a purple accent
- Guided graphical installation
- Core development tools available out of the box
- Developer Hub with a graphical interface and CLI
- Reproducible ISO builds
- Local user accounts without mandatory cloud sign-in

## Initial target

- Architecture: x86_64
- Base: a supported Fedora release
- Desktop: XFCE
- Dock: Plank
- Package management: DNF and RPM
- Build host: Fedora Linux

ARM64 support is a future goal and is not part of the initial release.

## Project status

NexOS is in early development. The Phase 2 baseline is complete: the
final Fedora 44 Xfce live ISO boots to the desktop under UEFI in QEMU
(the earlier Phase 1 ISO also booted under BIOS), and a clean UEFI install
boots the installed system with local login, networking, and enforcing
SELinux (2026-10-28). Installation is not yet validated on BIOS or physical
hardware.

Features and hardware compatibility will be verified through testing;
they should not be considered complete until documented and tested.

## Repository layout

- `build/` — ISO build configuration and scripts
- `desktop/` — XFCE configuration, themes, and branding
- `apps/` — NexOS applications
- `packaging/` — application packaging
- `config/` — system defaults and configuration
- `docs/` — architecture, setup, and development documentation
- `tests/` — build, ISO, VM, and hardware tests
- `assets/` — logos and brand assets

## Development

See [docs/Architecture.md](docs/Architecture.md) for the architecture. The detailed logs and work history are tracked in [docs/workcompleted.md](docs/workcompleted.md) and decisions in [docs/decisions/decisions.md](docs/decisions/decisions.md).

### Building the live ISO

Build host: Fedora 44 x86_64 with `sudo` access.

```sh
sudo dnf install kiwi-cli kiwi-systemdeps kiwi-systemdeps-iso-media \
    dracut-kiwi-live distribution-gpg-keys checkpolicy
make clone-vendor     # fetch pinned upstream descriptions (once)
make host-selinux     # install the nexos-kiwi-fix SELinux module (once)
make host-check
make build
```

Artifacts are written to `build/output/build/` (`Fedora.x86_64-44.iso`
plus checksum, package, and verification metadata).

Notes:

- `build/nexos-descr/` is generated from the pinned vendor tree plus
  `build/overlay/`; do not edit it directly.
- Keep SELinux Enforcing. D-010 documents the Fedora `kiwi_t` policy gap
  and the local module that fixes `%sysusers` scriptlets.
- The live root uses erofs + lzma without fragments (D-014). Packing it is
  memory-hungry; on a 7.5 GiB host, add swap (12 GiB was used during the
  baseline build) or `mkfs.erofs` will be OOM-killed.
- RPM GPG signature verification is enabled via
  `<rpm-check-signatures>true</rpm-check-signatures>` (D-011).

## Contributing

Keep changes small, test them locally, and document any important
architectural or security decisions.
