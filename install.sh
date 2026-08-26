#!/usr/bin/env bash
# OxiTide installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/yelanxin/OxiTide/main/install.sh | bash
#
# Detects your distribution, downloads the matching package from the latest
# GitHub release of yelanxin/OxiTide, and installs it with the native
# package manager. Supported: Arch, Fedora, openSUSE Tumbleweed, Debian,
# Ubuntu (and derivatives), x86_64 only.

set -euo pipefail

REPO="yelanxin/OxiTide"
API="https://api.github.com/repos/${REPO}/releases/latest"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

unsupported() {
  warn "$1"
  cat >&2 <<'EOF'
No native package matches this system. Other install options:
  Flatpak : flatpak install flathub io.github.yelanxin.OxiTide
  Snap    : sudo snap install oxitide --beta
  AUR     : yay -S oxitide-bin
EOF
  exit 1
}

[ "$(uname -s)" = "Linux" ] || die "OxiTide only supports Linux."
[ "$(uname -m)" = "x86_64" ] || unsupported "Only x86_64 packages are published (this system is $(uname -m))."
command -v curl >/dev/null 2>&1 || die "curl is required."
[ -r /etc/os-release ] || die "Cannot read /etc/os-release to detect the distribution."

# shellcheck disable=SC1091
. /etc/os-release
DISTRO_ID="${ID:-}"
DISTRO_LIKE="${ID_LIKE:-}"
DISTRO_VER="${VERSION_ID:-0}"

is_like() { printf '%s %s' "$DISTRO_ID" "$DISTRO_LIKE" | grep -qw "$1"; }

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || die "This script needs root privileges; install sudo or run as root."
  SUDO="sudo"
fi

info "Looking up the latest OxiTide release..."
json="$(curl -fsSL "$API")" || die "Failed to query the GitHub API (rate limited or offline?)."
tag="$(printf '%s' "$json" | grep -m1 '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"
urls="$(printf '%s' "$json" | grep -o '"browser_download_url": *"[^"]*"' | sed 's/.*"\(https[^"]*\)"$/\1/')"
[ -n "$urls" ] || die "The latest release ($tag) has no downloadable assets."
info "Latest release: $tag"

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

asset="" pm=""
if is_like arch; then
  pm="pacman"
  asset="$(printf '%s\n' "$urls" | grep 'archlinux\.pkg\.tar\.zst$' | head -n1 || true)"
elif is_like fedora && [ "$DISTRO_ID" != "opensuse-tumbleweed" ]; then
  pm="dnf"
  asset="$(printf '%s\n' "$urls" | sed -n 's/.*fedora\([0-9][0-9]*\)\.rpm$/\1 &/p' \
    | best_match "${DISTRO_VER%%.*}")"
elif is_like suse || is_like opensuse; then
  pm="zypper"
  asset="$(printf '%s\n' "$urls" | grep 'opensuse.*\.rpm$' | head -n1 || true)"
elif is_like ubuntu; then
  pm="apt"
  asset="$(printf '%s\n' "$urls" | sed -n 's/.*ubuntu\([0-9][0-9]*\)\.deb$/\1 &/p' \
    | best_match "${DISTRO_VER//./}")"
elif is_like debian; then
  pm="apt"
  asset="$(printf '%s\n' "$urls" | sed -n 's/.*debian\([0-9][0-9]*\)\.deb$/\1 &/p' \
    | best_match "${DISTRO_VER%%.*}")"
fi

[ -n "$asset" ] || unsupported "No package published for ${PRETTY_NAME:-$DISTRO_ID $DISTRO_VER}."

fname="${asset##*/}"
info "Selected package: $fname"
case "$fname" in
  *tumbleweed*|*archlinux*) : ;; # rolling releases: a single build covers all versions
  *"$DISTRO_ID"*"${DISTRO_VER%%.*}"*|*"${DISTRO_VER//./}"*) : ;;
  *) warn "No exact build for ${PRETTY_NAME:-$DISTRO_ID $DISTRO_VER}; installing the closest one. Dependency versions may mismatch." ;;
esac

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
info "Downloading..."
curl -fL --progress-bar -o "$tmpdir/$fname" "$asset"

info "Installing with $pm (may prompt for your password)..."
case "$pm" in
  pacman) $SUDO pacman -U --noconfirm "$tmpdir/$fname" ;;
  dnf)    $SUDO dnf install -y "$tmpdir/$fname" ;;
  zypper) $SUDO zypper --non-interactive install --allow-unsigned-rpm "$tmpdir/$fname" ;;
  apt)    $SUDO apt-get update -qq || true
          $SUDO apt-get install -y "$tmpdir/$fname" ;;
esac

info "OxiTide $tag installed successfully. Launch it with: oxitide"
