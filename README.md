# Build Control Tower Monitor

A macOS menu-bar app for watching [Build Control Tower](https://github.com/JoshuaSullivan/build-control-tower) — the daemon that serializes builds across every coding agent on a machine so they don't all compile at once and thrash the CPU.

The daemon runs headless and speaks JSON over loopback. This app puts its queue in your menu bar, so you can tell at a glance whether a build holds the slot, how far along it is, how many builds are stacked up behind it, and whether something is building *outside* the tower.

## What it shows

The status item is a constant hammer anchor plus one variable slot. The slot is always occupied — a label that changes width shoves every other menu-bar icon around, so the layout is deliberately fixed.

| State | Icon | Slot | Meaning |
| --- | --- | --- | --- |
| **Idle** | `hammer` | `zzz` | Daemon is reachable, nothing queued. |
| **Building** | `hammer.fill` | `47%` or `2m 13s` | A build holds the slot. Shows the agent's self-reported progress, falling back to elapsed time when it hasn't reported any. |
| **Blocked** | `hammer` | `pause.circle` | Builds are waiting but the daemon is withholding the slot — an unauthorized build (usually a manual ⌘B in Xcode) is burning CPU. |
| **Offline** | `hammer` | `exclamationmark.triangle` | The daemon couldn't be reached. |

A queue-depth badge appears once more than one build is in the system; a lone build needs no count.

Clicking the item opens a panel with the active build, the FIFO waiting list, and a health dot for the active build:

| Health | Icon | Meaning |
| --- | --- | --- |
| **Fresh** | green `circle.fill` | Checked in within the cadence the daemon asks agents to keep. |
| **Quiet** | yellow `circle.righthalf.filled` | Overdue for a check-in, but not near the reclaim window. |
| **Stale** | orange `exclamationmark.circle.fill` | Silent past the grace window. |

Health reports *reporting behaviour*, not liveness. The daemon reclaims a grant only when silence passes the grace window **and** its CPU probe sees no build running, so an agent that is quietly compiling keeps its slot. A silent build may be perfectly healthy — the monitor can't tell, so it prompts you to look rather than declaring anything broken. Colour is always a secondary cue; the symbol shape carries the same information.

## Requirements

- macOS 26.0 or later
- Xcode 26 (Swift 6.0) to build
- A running [build-control-tower](https://github.com/JoshuaSullivan/build-control-tower) daemon to monitor

## Install

```sh
./install.sh
```

That runs the test suite, builds the Release app, installs it to `~/Applications`, and registers a per-user launchd agent so the monitor auto-starts at login. No `sudo` — everything is per-user, mirroring the daemon's own layout.

```sh
./install.sh --skip-tests        # build without running tests first
./install.sh --uninstall-agent   # stop the monitor and remove the launchd agent
./install.sh --help
```

`--uninstall-agent` leaves the app in `~/Applications`; delete it to remove the monitor entirely.

Manage the agent directly if you need to:

```sh
launchctl kickstart -k gui/$(id -u)/com.hairlessape.BuildControlTowerMonitor   # restart
launchctl print gui/$(id -u)/com.hairlessape.BuildControlTowerMonitor         # status
```

The agent uses `KeepAlive`/`SuccessfulExit = false`, so it relaunches on crash but honors the app's own Quit command — quitting keeps it quit until the next login. Logs land in `~/Library/Logs/build-control-tower-monitor.log`.

## Configuration

### Port

The daemon binds `127.0.0.1` on the port in its `BCT_PORT` environment variable (default `7373`). A GUI app launched at login doesn't inherit your shell environment, so the port is resolved in this order:

1. a `UserDefaults` integer override,
2. the process environment's `BCT_PORT`, then
3. the built-in default, `7373`.

`install.sh` bakes the port it was run with into the launchd agent's environment, so the monitor follows the daemon:

```sh
BCT_PORT=7399 ./install.sh
```

To override an already-installed monitor without reinstalling:

```sh
defaults write com.hairlessape.BuildControlTowerMonitor BCTPort 7399
launchctl kickstart -k gui/$(id -u)/com.hairlessape.BuildControlTowerMonitor
```

### Daemon repository

The Daemon Control window shells out to the daemon repo's `build.sh`, so it needs to know where that checkout lives. Pick it once via the folder picker; the absolute path persists under the `BCTRepoPath` default. A folder is accepted only if it contains an executable `build.sh`, and the picker explains exactly which check failed if it doesn't.

## Daemon Control

Reachable from the menu panel. It reports whether the daemon is installed and running, and can act on it:

| Action | What it runs |
| --- | --- |
| **Install** | `build.sh --install-agent` (optionally `--skip-tests`) |
| **Uninstall** | `build.sh --uninstall-agent` |
| **Start** | `launchctl bootstrap gui/<uid> <plist>` |
| **Stop** | `launchctl bootout gui/<uid>/com.build-control-tower.daemon` |

Availability combines three independent signals: whether the daemon's LaunchAgent plist exists on disk, whether `launchctl` reports the job registered, and whether `/status` answers. The plist — not registration — is the "installed" signal, because `bootout` fully de-registers the job rather than pausing it; without the plist check, "stopped" and "never installed" would look identical.

The window also checks GitHub for a newer daemon release and compares it against the version the running daemon reports. A failed check is never an error — just "can't tell right now".

Daemon Control and About are real `Window` scenes rather than popover content, because an install can run for tens of seconds and must survive you clicking elsewhere.

## How it works

The app is a single `MenuBarExtra` scene running as an agent (`LSUIElement`), so it has no dock icon and no default window. The poll loop is owned by the menu-bar *label*, which is always present — the panel's content only exists while the menu is open.

`BuildStatusModel` polls `GET /status` every 5 seconds, backing off to 15 while offline so it isn't hammering a dead socket, with a 2-second per-request timeout so a hung daemon never stalls the UI. Requests go through an ephemeral, cache-disabled `URLSession`: `URLSession` will happily cache a loopback `200`, which would freeze the monitor on a stale snapshot.

Timing thresholds come from the daemon's `GET /config` rather than being hardcoded, since the queue's tuning is set per-install from the environment — a monitor assuming the defaults would silently disagree with any daemon launched with custom values. Config is re-read on every reconnect, which is the only moment the tuning can have changed. Daemons predating that endpoint answer `404`, so every field decodes leniently and falls back to the documented defaults.

The **blocked** state is an inference, but an exact one: the daemon advances the queue unless its probe sees a build already running, so a non-empty waiting line with no grant outstanding happens if and only if something outside the tower is building.

The app is unsandboxed, which it must be to shell out to `build.sh` and `launchctl`.

## Project layout

```
BuildControlTowerMonitor/          App sources
  BuildControlTowerMonitorApp      MenuBarExtra + auxiliary Window scenes
  BuildStatusModel                 Observable state and the poll loop
  StatusClient / StatusDTO         GET /status client and payload
  DaemonConfig                     GET /config timing policy
  MonitorState / BuildHealth       Derived display state
  MenuBarLabelContent              Menu-bar label rules, as pure data
  MonitorConfiguration             Port resolution
  Daemon*                          Daemon control: availability, commands, subprocess
  *View                            SwiftUI views
BuildControlTowerMonitorTests/     Swift Testing suites
install.sh                         Build, install, and register the launchd agent
```

Display rules are computed as pure, testable data — `MenuBarLabelContent`, `MonitorState`, `BuildHealth`, and `DaemonControlCommands` are all free of views and side effects, so the exact glyph, slot text, and subprocess invocation can be asserted without instantiating a view or launching anything.

## Development

```sh
xcodebuild test -project BuildControlTowerMonitor.xcodeproj \
    -scheme BuildControlTowerMonitor \
    -destination "platform=macOS,arch=$(uname -m)"
```

Or just `./install.sh`, which runs the suite before building.

The target uses Swift 6 language mode with `MainActor` default actor isolation and approachable concurrency, so SwiftUI-facing types need no explicit `@MainActor`; types that must cross actors are marked `nonisolated` instead.

## Troubleshooting

**"It says offline."** Check the daemon is actually up (`curl http://127.0.0.1:7373/status`) and that both sides agree on the port — see [Configuration](#port). The app logs every state transition; `log show --predicate 'subsystem == "com.hairlessape.BuildControlTowerMonitor"' --last 30m` will tell you what it saw.

**"It says blocked."** Something is building outside the tower — most often a manual ⌘B in Xcode. The queue resumes on its own once that build finishes.

**Xcode logs noise during `./install.sh`.** Xcode 26 emits `DVTDeviceOperation: Encountered a build number ""…` and `IDERunDestination: Supported platforms … is empty` on essentially every `xcodebuild` invocation. These are harmless and unrelated to this project; `install.sh` filters them so real failures aren't buried, and lets `xcodebuild`'s exit status be the only verdict.

**The monitor didn't come back after login.** Confirm the agent is registered with `launchctl print gui/$(id -u)/com.hairlessape.BuildControlTowerMonitor`. If you quit the app from its menu, that's expected — a clean exit stays quit until the next login.

## See also

- [build-control-tower](https://github.com/JoshuaSullivan/build-control-tower) — the daemon this app monitors

---

© 2026 Josh Sullivan
