# Feature matrix and roadmap

OxiTide is one playback engine, one TIDAL client and one application layer,
written in Rust, under three native front-ends: GTK4/libadwaita on Linux,
SwiftUI on macOS, WinUI 3 on Windows. Browsing and playback are the same
everywhere. What differs is how much of the surrounding app each front-end
has grown so far.

Linux is the reference build and gets features first. macOS shipped in
September 2025, Windows in this release.

**Legend** — ✓ shipped · ○ planned · — not on this platform today · n/a not
possible there.

## Browsing

| | Linux | macOS | Windows |
|---|:--:|:--:|:--:|
| Discover: Home, New, Top, Hi-Res, Genres, Decades, Moods | ✓ | ✓ | ✓ |
| Search across artists, albums, playlists and tracks | ✓ | ✓ | ✓ |
| Search history | ✓ | ○ | ○ |
| Library: tracks, albums, artists, playlists, mixes & radio, uploads | ✓ | ✓ | ✓ |
| History: Top 100, recent tracks, recent albums | ✓ | ✓ | ✓ |
| Album and artist pages | ✓ | ✓ | ✓ |
| Favourites, add to playlist | ✓ | ✓ | ✓ |

## Playback

| | Linux | macOS | Windows |
|---|:--:|:--:|:--:|
| Bit-perfect exclusive output at the track's own rate and bit depth | ✓ ALSA | ✓ CoreAudio hog mode | ✓ WASAPI exclusive |
| USB Rawlink, direct-to-DAC transport past the OS audio stack | ✓ | n/a | n/a |
| Hardware volume, with a software-gain fallback | ✓ | ✓ | ✓ |
| Gapless playback | ✓ | ✓ | ✓ |
| Play Next / Add to Queue, queue drawer, play modes | ✓ | ✓ | ✓ |
| Queue reordering and removal | ✓ | ○ | ○ |
| Streaming quality picker | ✓ | ✓ | ○ |
| DSP chain: PEQ, convolution, tube / tape, widener, limiter, resampler, presets | ✓ | ○ | ○ |

USB Rawlink is not possible on macOS or Windows: neither lets a user-space
process take the USB interface away from the in-box USB Audio driver the way
libusb does on Linux. CoreAudio hog mode and WASAPI exclusive mode are the
equivalent — the system mixer is out of the path and the device runs at the
source's own rate and format — but the OS driver still owns the transport.

## Now playing and UI

| | Linux | macOS | Windows |
|---|:--:|:--:|:--:|
| Now Playing page: Queue / Album / Suggested (track radio) / Lyrics tabs | ✓ | ✓ | ○ |
| Spectrum visualizer | ✓ | ✓ | ○ |
| LUFS / DR meter | ✓ | ○ | ○ |
| Lyrics drawer, synced and click-to-seek | ✓ | ✓ | ✓ |
| Mini player | ✓ | ✓ | ○ |
| Remembered window size and position | ✓ | ✓ | ✓ |
| Compact sidebar | — | ✓ | ✓ |
| Accent colour | — | ✓ | — |
| Grid / list layout and cover size for Tracks | — | ✓ | — |

## System integration

| | Linux | macOS | Windows |
|---|:--:|:--:|:--:|
| Last.fm / ListenBrainz scrobbling | ✓ | ✓ | ○ |
| Media keys and the system now-playing panel | ✓ MPRIS | ✓ | ○ |
| Tray / menu bar icon with transport controls; close hides the window | ✓ | ✓ | ○ |
| Keyboard shortcuts (Space, ← / →, S, W, Q, L, Esc) | ✓ | ✓ | ○ |
| Remote control HTTP JSON-RPC API | ✓ | ○ | ○ |
| In-app update check | ✓ | ○ | ○ |

## What is next

**Windows**, roughly in this order — the Now Playing page with the spectrum
visualizer and DR meter, media keys and the system media controls, the tray
icon, keyboard shortcuts, scrobbling, the streaming-quality picker, queue
editing, the mini player, then the DSP chain.

**macOS** — the DSP chain and its presets, the DR meter, queue editing and
search history; the remote control API and the update check after those.

**Linux** — the reference build; new features land here first and are ported
outward.

## Packaging

| | Status |
|---|---|
| Linux: Arch, Debian, Ubuntu, Fedora, openSUSE, Snap, Flatpak | shipped |
| macOS: universal `.app` (Apple silicon + Intel) | shipped, notarization planned |
| Windows: x64 installer and portable zip | shipped |
| Windows: arm64 build | planned |
| Windows: code signing, so SmartScreen stops warning | planned |
