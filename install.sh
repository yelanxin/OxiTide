#!/usr/bin/env bash
# OxiTide installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/yelanxin/OxiTide/main/install.sh | bash
#
# Linux: detects your distribution, downloads the matching package from the
# newest GitHub release of yelanxin/OxiTide that has one, and installs it
# with the native package manager. Supported: Arch, Fedora, openSUSE
# Tumbleweed, Debian, Ubuntu (and derivatives), x86_64 only.
#
# macOS: downloads the newest universal .app (Apple silicon and Intel,
# macOS 14 or later), verifies its checksum and puts it in /Applications.
#
# Environment:
#   OXITIDE_INSTALL_DIR  macOS: where the .app goes (default /Applications)
#   OXITIDE_DRY_RUN=1    print what would be installed and stop

set -euo pipefail

REPO="yelanxin/OxiTide"
API="https://api.github.com/repos/${REPO}/releases?per_page=30"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "curl is required."

OS="$(uname -s)"
case "$OS" in
  Linux|Darwin) ;;
  *) die "OxiTide supports Linux and macOS (this system is $OS)." ;;
esac

# ---------------------------------------------------------------------------
# Releases
# ---------------------------------------------------------------------------

info "Looking up OxiTide releases..."
json="$(curl -fsSL -H 'Accept: application/vnd.github+json' "$API")" \
  || die "Failed to query the GitHub API (rate limited or offline?)."

# The listing, newest first, flattened to "<tag> <url>" lines for every
# asset of every published (non-draft, non-pre-release) release. The
# fields come in document order — tag_name, draft, prerelease, then the
# assets — which is what the awk below relies on.
assets="$(printf '%s' "$json" \
  | grep -oE '"(tag_name|draft|prerelease|browser_download_url)": *("[^"]*"|true|false)' \
  | sed -E 's/^"([a-z_]+)": *"?([^"]*)"?$/\1 \2/' \
  | awk '
      $1 == "tag_name"             { tag = $2; skip = 0; next }
      $1 == "draft" && $2 == "true" { skip = 1; next }
      $1 == "prerelease" && $2 == "true" { skip = 1; next }
      $1 == "browser_download_url" && !skip { print tag, $2 }
    ')"
[ -n "$assets" ] || die "No published releases with downloadable assets found."

# Tags in the order they appear (newest first), each once.
tags="$(printf '%s\n' "$assets" | awk '!seen[$1]++ { print $1 }')"

# URLs of one release.
urls_of() { printf '%s\n' "$assets" | awk -v t="$1" '$1 == t { print $2 }'; }

# stdin: lines of "<distro-version> <url>"; picks exact match on $1,
# else the closest lower version, else the lowest published one.
best_match() {
  local target="$1" num url exact="" lower="" lower_n=-1 min="" min_n=99999999
  while read -r num url; do
    [ -n "$url" ] || continue
    [ "$num" = "$target" ] && exact="$url"
    if [ "$num" -le "$target" ] 2>/dev/null && [ "$num" -gt "$lower_n" ]; then
      lower="$url" lower_n="$num"
    fi
    if [ "$num" -lt "$min_n" ]; then
      min="$url" min_n="$num"
    fi
  done
  if [ -n "$exact" ]; then printf '%s' "$exact"
  elif [ -n "$lower" ]; then printf '%s' "$lower"
  else printf '%s' "$min"; fi
}

# ---------------------------------------------------------------------------
# macOS
# ---------------------------------------------------------------------------

install_macos() {
  local dir="${OXITIDE_INSTALL_DIR:-/Applications}"
  local tag="" asset="" urls
  for t in $tags; do
    urls="$(urls_of "$t")"
    asset="$(printf '%s\n' "$urls" | grep -- '-macos-universal\.zip$' | head -n1 || true)"
    if [ -n "$asset" ]; then tag="$t"; break; fi
  done
  [ -n "$asset" ] || die "No macOS build has been published yet."
  local fname="${asset##*/}"
  info "Latest macOS release: $tag ($fname)"
  if [ "${OXITIDE_DRY_RUN:-0}" = "1" ]; then
    info "Dry run: would install $asset into $dir"
    exit 0
  fi


  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  info "Downloading..."
  curl -fL --progress-bar -o "$tmpdir/$fname" "$asset"
  if curl -fsSL -o "$tmpdir/$fname.sha256" "$asset.sha256" 2>/dev/null; then
    info "Verifying checksum..."
    (cd "$tmpdir" && shasum -a 256 -c --status "$fname.sha256") \
      || die "Checksum mismatch for $fname; not installing."
  else
    warn "No checksum published for $fname; skipping verification."
  fi

  info "Unpacking..."
  ditto -x -k "$tmpdir/$fname" "$tmpdir/unpacked"
  local app="$tmpdir/unpacked/OxiTide.app"
  [ -d "$app" ] || die "The archive did not contain OxiTide.app."
  # Not notarized: the download would otherwise be refused on first
  # launch until allowed in System Settings > Privacy & Security.
  xattr -dr com.apple.quarantine "$app" 2>/dev/null || true

  local sudo=""
  if [ ! -w "$dir" ]; then
    command -v sudo >/dev/null 2>&1 || die "$dir is not writable and sudo is unavailable."
    sudo="sudo"
    info "$dir needs administrator rights (may prompt for your password)..."
  fi
  if pgrep -x OxiTide >/dev/null 2>&1; then
    warn "OxiTide is running; quit it and relaunch after the install to pick up the new version."
  fi
  if [ -d "$dir/OxiTide.app" ]; then
    $sudo rm -rf "$dir/OxiTide.app"
  fi
  $sudo ditto "$app" "$dir/OxiTide.app"

  info "OxiTide $tag installed to $dir/OxiTide.app. Launch it from Launchpad or with: open -a OxiTide"
}

# ---------------------------------------------------------------------------
# Linux
# ---------------------------------------------------------------------------

unsupported() {
  warn "$1"
  cat >&2 <<'EOT'
No native package matches this system. Other install options:
  Flatpak : flatpak install --user https://flatpak.oxitide.com/oxitide.flatpakref
  Snap    : sudo snap install oxitide
  AUR     : yay -S oxitide-bin
EOT
  exit 1
}

# Picks the package for this distribution out of one release's URLs;
# prints nothing when the release has none.
linux_asset() {
  local urls="$1"
  if is_like arch; then
    printf '%s\n' "$urls" | grep 'archlinux\.pkg\.tar\.zst$' | head -n1 || true
  elif is_like fedora && [ "$DISTRO_ID" != "opensuse-tumbleweed" ]; then
    printf '%s\n' "$urls" | sed -n 's/.*fedora\([0-9][0-9]*\)\.rpm$/\1 &/p' \
      | best_match "${DISTRO_VER%%.*}"
  elif is_like suse || is_like opensuse; then
    printf '%s\n' "$urls" | grep 'opensuse.*\.rpm$' | head -n1 || true
  elif is_like ubuntu; then
    printf '%s\n' "$urls" | sed -n 's/.*ubuntu\([0-9][0-9]*\)\.deb$/\1 &/p' \
      | best_match "${DISTRO_VER//./}"
  elif is_like debian; then
    printf '%s\n' "$urls" | sed -n 's/.*debian\([0-9][0-9]*\)\.deb$/\1 &/p' \
      | best_match "${DISTRO_VER%%.*}"
  fi
}

install_linux() {
  [ "$(uname -m)" = "x86_64" ] || unsupported "Only x86_64 packages are published (this system is $(uname -m))."
  [ -r /etc/os-release ] || die "Cannot read /etc/os-release to detect the distribution."

  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO_ID="${ID:-}"
  DISTRO_LIKE="${ID_LIKE:-}"
  DISTRO_VER="${VERSION_ID:-0}"
  is_like() { printf '%s %s' "$DISTRO_ID" "$DISTRO_LIKE" | grep -qw "$1"; }

  local pm=""
  if is_like arch; then pm="pacman"
  elif is_like fedora && [ "$DISTRO_ID" != "opensuse-tumbleweed" ]; then pm="dnf"
  elif is_like suse || is_like opensuse; then pm="zypper"
  elif is_like ubuntu || is_like debian; then pm="apt"
  fi
  [ -n "$pm" ] || unsupported "No package published for ${PRETTY_NAME:-$DISTRO_ID $DISTRO_VER}."

  # The newest release that carries a package for this distribution: a
  # release for another platform only, or one with no package for this
  # distribution yet, is passed over.
  local tag="" asset="" urls
  for t in $tags; do
    urls="$(urls_of "$t")"
    asset="$(linux_asset "$urls")"
    if [ -n "$asset" ]; then tag="$t"; break; fi
  done
  [ -n "$asset" ] || unsupported "No package published for ${PRETTY_NAME:-$DISTRO_ID $DISTRO_VER}."

  local fname="${asset##*/}"
  info "Latest Linux release: $tag"
  info "Selected package: $fname"
  case "$fname" in
    *tumbleweed*|*archlinux*) : ;; # rolling releases: a single build covers all versions
    *"$DISTRO_ID"*"${DISTRO_VER%%.*}"*|*"${DISTRO_VER//./}"*) : ;;
    *) warn "No exact build for ${PRETTY_NAME:-$DISTRO_ID $DISTRO_VER}; installing the closest one. Dependency versions may mismatch." ;;
  esac
  if [ "${OXITIDE_DRY_RUN:-0}" = "1" ]; then
    info "Dry run: would install $asset with $pm"
    exit 0
  fi

  local sudo=""
  if [ "$(id -u)" -ne 0 ]; then
    command -v sudo >/dev/null 2>&1 || die "This script needs root privileges; install sudo or run as root."
    sudo="sudo"
  fi


  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  info "Downloading..."
  curl -fL --progress-bar -o "$tmpdir/$fname" "$asset"

  info "Installing with $pm (may prompt for your password)..."
  case "$pm" in
    pacman) $sudo pacman -U --noconfirm "$tmpdir/$fname" ;;
    dnf)    $sudo dnf install -y "$tmpdir/$fname" ;;
    zypper) $sudo zypper --non-interactive install --allow-unsigned-rpm "$tmpdir/$fname" ;;
    apt)    $sudo apt-get update -qq || true
            $sudo apt-get install -y "$tmpdir/$fname" ;;
  esac

  info "OxiTide $tag installed successfully. Launch it with: oxitide"
}

case "$OS" in
  Darwin) install_macos ;;
  Linux)  install_linux ;;
esac
