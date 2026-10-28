# NexOS Design Specification

**Status:** Initial specification  
**Project:** NexOS  
**Base distribution:** Fedora Linux 44 (initial x86_64 target)  
**Desktop environment:** Xfce  
**Primary goal:** Build a lightweight, developer-focused Fedora-based Linux distribution with a consistent identity, useful development tools, and a straightforward installation experience.

## 1. Product vision

NexOS should feel like a focused developer workstation rather than a generic Fedora remix. It should provide a usable desktop, a dependable development baseline, clear branding, and an optional app-management experience without requiring a cloud account.

The first milestone is a repeatable, bootable x86_64 live ISO. Do not treat a successful package installation or an untested ISO build as a completed release.

## 2. Target users

- Students and beginner developers setting up a Linux development environment.
- Developers who want a practical workstation without manually installing the initial toolchain.
- Users who prefer local accounts and offline-capable desktop use.

## 3. Design principles

1. **Fedora-first:** Use Fedora-supported packages, repositories, and image-building conventions wherever practical.
2. **Lightweight by measurement:** Avoid unnecessary services and duplicated desktop components. Measure memory use instead of promising a RAM target without evidence.
3. **Offline-capable:** Core desktop usage must not require a NexOS cloud account or network service.
4. **Transparent operations:** Explain package changes and privileged actions before executing them.
5. **Maintainable customization:** Keep NexOS changes separate from vendored Fedora source.
6. **Accessible and usable:** Clear labels, keyboard navigation, legible contrast, and sensible defaults.
7. **Recoverable:** Document how to reproduce builds, diagnose failures, and roll back changes.

## 4. Visual identity

- Product name: **NexOS**
- Desktop: **Xfce**
- Accent: **Purple**
- Theme modes: **Light and dark**
- Overall style: clean, modern, restrained, developer-oriented
- Desktop layout: top panel, dock, application launcher, workspace support
- Dock: Plank, if compatible with the chosen Fedora 44 package sources and Xfce session
- Branding must not impersonate Fedora's official identity. Clearly identify NexOS as a community/custom distribution based on Fedora.

### Branding locations

Plan consistent NexOS branding for:
- Boot menu and live-session labels, where supported by the image build system
- Wallpaper and lock screen
- Xfce panel, launcher, and session defaults
- Login/greeter screen
- About/system-information page
- Installer branding only where supported without breaking Anaconda
- Documentation and release metadata

Use original or appropriately licensed artwork. Keep source assets and license/attribution notes in the repository.

## 5. Desktop experience

The first release should use Xfce rather than introduce a second desktop environment.

Expected experience:
- Familiar top panel with applications, status indicators, clock, and workspace controls.
- Plank dock with a small curated set of applications, if it behaves reliably in the Xfce session.
- Application launcher that remains usable without the dock.
- Light and dark themes with a consistent purple accent.
- Sensible default fonts, icons, wallpaper, and display settings.
- Avoid duplicate launchers, duplicate panels, autostart loops, or unnecessary background services.

Do not make the dock or theme customization a blocker for producing the first bootable ISO.

## 6. Development tools

Core tools to evaluate for preinstallation:
- Git
- Python 3, pip, and virtual-environment support
- Node.js and npm
- OpenJDK
- Firefox
- Visual Studio Code from an appropriate official distribution source, subject to licensing, repository, and redistribution constraints

Do not silently add third-party repositories or redistribute proprietary packages. Document package origins and licensing. If a tool is better offered as an optional Developer Hub installation, explain why.

## 7. Developer Hub

The Developer Hub is a planned native GUI and CLI for discovering and installing optional developer tools.

Initial implementation preference:
- Python
- GTK 4 and PyGObject for the native GUI, if compatible with the target Fedora release
- A shared service layer used by both GUI and CLI
- DNF/RPM for package management

Requirements:
- Catalog entries are structured, reviewed data—not executable shell snippets.
- Never execute arbitrary commands supplied by catalog metadata.
- Validate package IDs and supported repositories.
- Use a supported privilege mechanism such as PackageKit/polkit or a narrowly scoped privileged helper, after checking Fedora 44 capabilities.
- Show package name, source, approximate impact, and requested changes before installation.
- Surface command/package-manager errors clearly.
- Support offline operation for browsing installed tools and showing status.
- Log actions without recording secrets.
- Keep the GUI optional so the base OS remains usable if it fails.

The Developer Hub is a later phase. Do not delay the first live ISO to build it.

## 8. Installer and live session

- Start from the Fedora 44 Xfce live profile where technically appropriate.
- Preserve the Fedora-supported Anaconda live installation workflow unless testing shows it cannot meet requirements.
- Do not claim that installation works until tested end-to-end in a VM and on physical hardware.
- Test UEFI boot first; test legacy BIOS only if the selected image supports it and it is a stated requirement.
- Verify live-session startup, installer launch, target-disk selection, installation, first boot, user creation, networking, and shutdown.
- Keep local accounts supported. No required cloud sign-in.

## 9. Performance and reliability

- Measure idle RAM, boot time, ISO size, and disk usage on documented hardware.
- The earlier 4 GB RAM target is an aspiration, not a guarantee; validate it with representative tests.
- Avoid disabling security services solely to reduce resource use.
- Test suspend/resume, audio, networking, display scaling, and common laptop hardware where possible.

## 10. Release acceptance criteria

A release candidate is not complete until:
- The ISO can be reproduced from documented steps.
- The image boots in a UEFI VM.
- The live desktop starts and basic applications work.
- Anaconda launches and a test installation completes.
- The installed system boots and creates/uses a local account.
- Package updates work through the intended Fedora repositories.
- Branding and licenses are reviewed.
- No critical errors remain in the build or boot logs.
- `README.md`, `workcompleted.md`, and `decisions.md` are updated.
- Known limitations and test evidence are recorded.
