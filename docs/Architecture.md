# NexOS Architecture

**Status:** Initial architecture; validate all implementation details against Fedora 44 and the actual build environment.

## 1. Architecture goals

- Keep the first ISO build simple, repeatable, and auditable.
- Keep upstream Fedora image definitions separate from NexOS customizations.
- Prefer supported Fedora packages and image-building mechanisms.
- Make optional features fail independently rather than making the OS unusable.
- Record reproducible commands, package sources, decisions, and test evidence.

## 2. High-level layers

```text
Build inputs and release configuration
        |
        v
Fedora 44 image definition (vendored, pinned revision)
        |
        +---- NexOS overlay/configuration
        |       +---- branding assets
        |       +---- package selections
        |       +---- Xfce defaults and themes
        |       +---- boot/live-session overrides
        |
        v
KIWI image build
        |
        v
Live ISO artifact
        |
        +---- VM boot and live-session tests
        +---- Anaconda installation tests
        +---- physical hardware smoke tests
        |
        v
Release artifact + checksums + documentation
```

Later, the optional Developer Hub sits above the base OS package-management layer:

```text
Developer Hub GUI (GTK 4) ----\
                               +---- shared service layer
Developer Hub CLI ------------/          |
                                          v
                              validated package catalog
                                          |
                                          v
                              supported package backend
                              (DNF/RPM and authorized
                               privileged operations)
```

## 3. Build system

### Current known state

- Host: Fedora 44, x86_64.
- KIWI CLI: `kiwi-cli` 11.1.1 installed.
- KIWI system dependencies: `kiwi-systemdeps` 11.1.1 installed.
- ISO media dependencies: `kiwi-systemdeps-iso-media` installed.
- `distribution-gpg-keys` installed.
- Fedora KIWI descriptions repository is checked out at `origin/f44`, commit `dfc49a5` at the time of initial investigation.
- Fedora's `Xfce-Live` profile requires `Xfce-Desktop` and `LiveInstall`.
- `LiveInstall` includes Anaconda live installer components.
- The exact presence/need of `dracut-kiwi-live` and any other dependencies must be verified locally; do not infer success from package names alone.
- Do not use the Rawhide branch for the Fedora 44 baseline.

### Build isolation

- Vendored Fedora definitions live under `build/vendor/fedora-kiwi-descriptions/`.
- Keep this directory pinned to a known Fedora release commit.
- Do not patch vendor files directly for ordinary NexOS customization.
- Prefer a NexOS KIWI description/overlay or a minimal, documented patch carried by NexOS.
- If the KIWI tooling requires a modified description, copy only the required files into a separate NexOS-owned build directory and record the upstream commit and patch rationale.
- Never run the build as root unless KIWI explicitly requires it; prefer the tool's supported privilege model. If root is required, explain why and limit writable paths.

## 4. Repository layout

The repository may evolve, but keep responsibilities clear. Inspect the existing tree before adding or moving files.

```text
nexos/
├── README.md
├── workcompleted.md
├── decisions.md
├── docs/
│   ├── design.md
│   ├── Architecture.md
│   ├── rules.md
│   └── implementation.md
├── build/
│   ├── vendor/
│   │   └── fedora-kiwi-descriptions/   # pinned upstream checkout; not NexOS source
│   ├── config/                         # NexOS build configuration
│   ├── scripts/                        # validated build/test helpers
│   └── output/                         # generated artifacts; gitignored
├── desktop/
│   ├── themes/
│   ├── wallpapers/
│   ├── icons/
│   └── xfce/
├── apps/
│   └── developer-hub/
│       ├── src/
│       ├── tests/
│       └── packaging/
├── packaging/
├── config/
├── tests/
└── assets/
```

This is a target organization, not a command to move files blindly. Check current contents and avoid destructive reorganizations.

## 5. Package and configuration management

- Use Fedora 44 package names verified with DNF/repoquery.
- Prefer RPM packages from Fedora repositories for core components.
- Track third-party package sources explicitly.
- Never embed credentials, tokens, or personal paths into image configuration.
- Avoid installing packages using `curl | sh`.
- Keep package lists in version-controlled, reviewable files.
- Separate required packages from recommended and optional packages.
- Preserve Fedora security defaults unless a documented, tested reason justifies a change.

## 6. Desktop session

- Xfce is the base desktop.
- Configure panels, themes, icons, wallpaper, and autostart through supported Xfce configuration mechanisms.
- Plank is optional until session behavior and package availability are verified.
- Avoid duplicate autostart entries and session components.
- Keep keyboard-accessible launch options even if a dock is installed.

## 7. Developer Hub security boundary

The Developer Hub must not have unrestricted root access.

- Catalog metadata may specify a known backend action and validated package identifiers, but never arbitrary shell commands.
- All inputs must be validated.
- Privileged operations require an explicit supported authorization flow.
- The UI and CLI must call the same service layer.
- Do not store credentials.
- Record enough diagnostic information to debug failures, without logging secrets.
- Tests must cover invalid package IDs, unavailable repositories, failed installs, cancellation, and authorization denial.

## 8. Testing layers

1. Static checks: shell syntax, Python lint/type checks where configured, XML/config validation where tools exist.
2. Build checks: required packages, pinned upstream revision, valid profile, build result files.
3. VM checks: UEFI boot, live session, network, installer, installation, first boot.
4. Hardware smoke tests: Wi-Fi, graphics, audio, suspend/resume, external display.
5. Release checks: checksums, metadata, licensing, documented limitations.

## 9. Artifacts and reproducibility

- Place generated files in `build/output/` or another clearly documented ignored directory.
- Record the source commit, Fedora release, build command, build host details, and artifact checksum.
- Do not commit large generated ISOs unless the repository policy explicitly calls for it.
- Avoid claiming deterministic builds unless repeatability has been demonstrated.
