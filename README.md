# OxiTide

**OxiTide** is a high-resolution TIDAL player for Linux, written entirely in Rust.

It is the native successor to [hiresTI](https://github.com/yelanxin/hiresTI) — same bit-perfect playback engine, same USB Rawlink direct-to-DAC output, rebuilt from the ground up with a native Rust UI: faster startup, lower memory, no Python runtime.

![OxiTide — Home](screenshots/oxitide-home.png)

## Highlights

- **Bit-perfect playback** — untouched PCM straight to your DAC
- **USB Rawlink** — direct USB audio transport, bypassing the OS mixer entirely
- **Hi-Res / FLAC streaming** with gapless playback
- **Native performance** — a single self-contained binary, instant startup
- Spectrum visualizer, level meter, synced lyrics, MPRIS integration

## Install

OxiTide is **free to use**. Packages for every supported distribution are on the
[**Releases**](https://github.com/yelanxin/OxiTide-release/releases) page.

| Distribution | Install |
|---|---|
| Arch Linux / Manjaro / CachyOS | `yay -S oxitide-bin` (AUR: [oxitide-bin](https://aur.archlinux.org/packages/oxitide-bin)) — or `sudo pacman -U oxitide-<ver>-1-x86_64_archlinux.pkg.tar.zst` |
| Debian 13+ | `sudo apt install ./oxitide_<ver>_amd64_debian13.deb` |
| Ubuntu 24.04 / 26.04 | `sudo apt install ./oxitide_<ver>_amd64_ubuntu2404.deb` (or `_ubuntu2604.deb`) |
| Fedora 43 / 44 | `sudo dnf install ./oxitide-<ver>-1.fedora.x86_64_fedora44.rpm` (or `_fedora43.rpm`) |
| openSUSE Tumbleweed | `sudo zypper install ./oxitide-<ver>-1.opensuse.x86_64_opensuse_tumbleweed.rpm` |

Requirements: a TIDAL subscription and GTK 4.14+ (Debian 12 is not supported).
For bit-perfect USB Rawlink output the package installs a udev rule and a polkit
action so the app can claim your DAC — the first use asks for authorization.

Settings and login live in `~/.config/oxitide`, so OxiTide installs cleanly
alongside hiresTI.

### Updating

Packages: download the new version and install it the same way (the package
manager upgrades in place). AUR: `yay -Syu`. The app also checks for new
releases itself (**Check for Updates** in the menu).

## License

OxiTide is proprietary freeware — free to download and use, not open source.
Redistribution of modified binaries is not permitted. Third-party open-source
components are acknowledged in the `THIRD-PARTY-NOTICES` file shipped with each release.

Looking for the open-source edition? The Python/GTK version lives on at
[hiresTI](https://github.com/yelanxin/hiresTI) (GPL-3.0).

## Feedback

Bug reports and feature requests are welcome in the
[Issues](https://github.com/yelanxin/OxiTide-release/issues) of this repository.

---

*OxiTide is an independent project and is not affiliated with or endorsed by TIDAL.*
