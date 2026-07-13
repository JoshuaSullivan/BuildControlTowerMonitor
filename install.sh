#!/usr/bin/env bash
#
# Build Control Tower Monitor — build & install helper.
#
# Builds the release .app, installs it to ~/Applications, and registers a
# per-user launchd agent so the menu-bar monitor auto-starts at login.
#
set -euo pipefail
cd "$(dirname "$0")"

LABEL="com.hairlessape.BuildControlTowerMonitor"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_FILE="$HOME/Library/Logs/build-control-tower-monitor.log"
DOMAIN="gui/$(id -u)"

# Port the daemon listens on. Baked into the agent's environment so the monitor
# always polls the same port the daemon was installed with (default 7373).
PORT="${BCT_PORT:-7373}"

PROJECT="BuildControlTowerMonitor.xcodeproj"
SCHEME="BuildControlTowerMonitor"
APP_NAME="BuildControlTowerMonitor.app"
# Per-user install location: no sudo, mirrors the daemon's per-user layout.
INSTALL_DIR="$HOME/Applications"
DERIVED="$(pwd)/.build"

RUN_TESTS=1

usage() {
    cat <<USAGE
Build Control Tower Monitor — build & install helper.

Usage:
  ./install.sh                  Run tests, build the release app, install it to
                                $INSTALL_DIR, and start it as an auto-starting
                                launchd agent.
  ./install.sh --skip-tests     Build without running the test suite first.
  ./install.sh --uninstall-agent  Stop the monitor and remove the launchd agent.
  ./install.sh --help           Show this help.

Environment:
  BCT_PORT   Port the daemon listens on (default 7373); baked into the agent so
             the monitor matches the daemon's port.
USAGE
}

write_agent_plist() {
    local exe="$1"
    mkdir -p "$(dirname "$PLIST")" "$(dirname "$LOG_FILE")"
    cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$exe</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>BCT_PORT</key>
        <string>$PORT</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <!-- Relaunch on crash, but honor the app's Quit command (a clean exit 0
         stays quit until the next login). -->
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardOutPath</key>
    <string>$LOG_FILE</string>
    <key>StandardErrorPath</key>
    <string>$LOG_FILE</string>
</dict>
</plist>
PLIST
}

bootstrap_agent() {
    launchctl bootout "$DOMAIN" "$PLIST" 2>/dev/null || true
    if ! launchctl bootstrap "$DOMAIN" "$PLIST" 2>/dev/null; then
        # Fall back to the legacy launchctl API on older systems.
        launchctl unload "$PLIST" 2>/dev/null || true
        launchctl load -w "$PLIST"
    fi
    launchctl kickstart -k "$DOMAIN/$LABEL" 2>/dev/null || true
}

uninstall_agent() {
    launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null \
        || launchctl bootout "$DOMAIN" "$PLIST" 2>/dev/null \
        || launchctl unload "$PLIST" 2>/dev/null || true
    rm -f "$PLIST"
    echo "Stopped and removed the launchd agent ($LABEL); it will no longer auto-start."
    echo "The app itself is still at $INSTALL_DIR/$APP_NAME — delete it to remove entirely."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-tests) RUN_TESTS=0; shift ;;
        --uninstall-agent) uninstall_agent; exit 0 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "error: unknown argument '$1'" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ "$RUN_TESTS" -eq 1 ]]; then
    echo "==> Running tests..."
    xcodebuild test -project "$PROJECT" -scheme "$SCHEME" \
        -destination 'platform=macOS' -quiet
fi

echo "==> Building release app..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
    -derivedDataPath "$DERIVED" -destination 'platform=macOS' -quiet build

APP_SRC="$DERIVED/Build/Products/Release/$APP_NAME"
[[ -d "$APP_SRC" ]] || { echo "error: built app not found at $APP_SRC" >&2; exit 1; }

echo "==> Installing to $INSTALL_DIR/$APP_NAME"
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME"
cp -R "$APP_SRC" "$INSTALL_DIR/"
EXE="$INSTALL_DIR/$APP_NAME/Contents/MacOS/BuildControlTowerMonitor"
[[ -x "$EXE" ]] || { echo "error: app executable not found at $EXE" >&2; exit 1; }

write_agent_plist "$EXE"
bootstrap_agent

cat <<EOF

Build Control Tower Monitor is running and will auto-start at login.
  App:   $INSTALL_DIR/$APP_NAME
  Port:  $PORT (polls http://127.0.0.1:$PORT/status)
  Logs:  $LOG_FILE

Look for the hammer icon in the menu bar. Use its Quit command to stop it until
the next login, or manage the agent directly:
  Restart:   launchctl kickstart -k $DOMAIN/$LABEL
  Status:    launchctl print $DOMAIN/$LABEL
  Remove:    ./install.sh --uninstall-agent
EOF
