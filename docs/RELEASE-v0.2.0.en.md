[Español](RELEASE-v0.2.0.md) · [English](RELEASE-v0.2.0.en.md)

# Logical Unplug v0.2.0

Share a monitor between your Mac and another computer without unplugging cables. This version turns the original script into a native app with graphical controls.

## What's new

- Choose a monitor from a list, without hardcoded names or identifiers.
- Disable and re-enable it from the window or menu bar.
- macOS display status refreshed every two seconds, with your selection saved.
- Recover displays button for outputs that no longer appear.
- Primary and built-in display safeguards, with visible error messages.
- Custom app icon and optional Terminal commands.
- No Python, Homebrew, or displayplacer required.

The v0.2.0 app interface and CLI messages are in Spanish. [Read the English user guide](../README.en.md) for translated button descriptions.

## Installation

Download **LogicalUnplug-v0.2.0-macOS-arm64.zip**, unzip it, and drag **LogicalUnplug.app** into Applications.

**Platform:** Apple Silicon (M1 or later), with a minimum deployment target of macOS 13. Build, launch, display detection, and 11 logic cases were checked locally on an M4 Mac running macOS 26. The physical input-switching cycle must be validated on your monitor; compatibility with every setup is not guaranteed.

**Signing:** ad hoc; not yet Developer ID signed or notarized. macOS may require first-launch authorization in System Settings → Privacy & Security. [Apple's guide](https://support.apple.com/en-ca/guide/mac-help/mh40616/mac).

## How it works

The app disables the Mac's video output. If your monitor supports automatic signal detection, it can switch to the cable connected to the other computer. When you re-enable the display, you may need to select the Mac's input. The app does not control physical input selection, your keyboard, or your mouse.

Recover displays attempts to re-enable all compatible hidden outputs, only when requested. The control uses a private macOS API that may change in future versions.

## Credits

Alexis Lopez; @alex-konkov for the original recovery mechanism; Jake Hilborn/displayplacer as the tool used by the initial version and a technical reference, not a dependency of this release. Icon generated with OpenAI ImageGen; screenshot provided by Alexis Lopez.
