#!/bin/sh
# Zero Control installer for Linux. Installs for the current user only:
#   ~/.local/bin/zero-control, a menu entry and an icon. No root needed.
set -eu

BASE="${ZEROCONTROL_BASE:-https://zero.skillissue.gg/zero-control}"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"

if [ "$(uname -m)" != "x86_64" ]; then
    echo "Zero Control currently ships for 64-bit Intel/AMD Linux only (this is $(uname -m))." >&2
    exit 1
fi

fetch() {
    if command -v curl >/dev/null 2>&1; then curl -fL --progress-bar "$1" -o "$2"
    elif command -v wget >/dev/null 2>&1; then wget -q --show-progress "$1" -O "$2"
    else echo "Install curl or wget first." >&2; exit 1
    fi
}

mkdir -p "$BIN_DIR" "$APP_DIR" "$ICON_DIR"
echo "Downloading Zero Control…"
fetch "$BASE/download/zero-control-linux-x86_64" "$BIN_DIR/zero-control.new"
chmod 755 "$BIN_DIR/zero-control.new"
mv -f "$BIN_DIR/zero-control.new" "$BIN_DIR/zero-control"
fetch "$BASE/icon.svg" "$ICON_DIR/zero-control.svg" 2>/dev/null || true

cat >"$APP_DIR/zero-control.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Zero Control
Comment=Lightweight remote desktop
Exec=$BIN_DIR/zero-control
Icon=zero-control
Terminal=false
Categories=Network;RemoteAccess;
StartupWMClass=zero-control
DESKTOP
update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true

# Zero Control uses the system's GStreamer for video. Say exactly what to
# install if something is missing instead of failing at first use.
if ! "$BIN_DIR/zero-control" --selftest >/tmp/zero-control-selftest.$$ 2>&1; then
    echo
    echo "Installed, but some system video components are missing:"
    grep -i "missing\|error" /tmp/zero-control-selftest.$$ || cat /tmp/zero-control-selftest.$$
    echo
    echo "Install them with your package manager, then start Zero Control:"
    if command -v pacman >/dev/null 2>&1; then
        echo "  sudo pacman -S --needed gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-plugin-pipewire gst-plugin-va gst-libav libnice"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "  sudo apt install gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-nice gstreamer1.0-pipewire gstreamer1.0-vaapi"
    elif command -v dnf >/dev/null 2>&1; then
        echo "  sudo dnf install gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad-free gstreamer1-plugins-ugly-free gstreamer1-plugin-libav libnice-gstreamer1 pipewire-gstreamer"
    else
        echo "  GStreamer 1.22+ with the base, good, bad, ugly, libav, nice and pipewire plugins"
    fi
    rm -f /tmp/zero-control-selftest.$$
    exit 0
fi
rm -f /tmp/zero-control-selftest.$$

echo
echo "Zero Control is installed. Find it in your application menu, or run: zero-control"
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "(Add $BIN_DIR to your PATH to start it by name from a terminal.)" ;;
esac
