[Español](RELEASE-v0.3.0.md) · [English](RELEASE-v0.3.0.en.md)

# Logical Unplug v0.3.0

The app is now available in English and Spanish.

## What's new

- **Language / Idioma** selector with English, Español, and Automatic (system).
- Instant language changes without restarting the app or changing display state.
- A saved preference shared with the CLI and retained across launches.
- Translated buttons, status messages, menu bar controls, errors, and help.
- `--language es|en|system` to choose a language for one CLI invocation only.

## Install

Download `LogicalUnplug-v0.3.0-macOS-arm64.zip`, unzip it, and copy `LogicalUnplug.app` to Applications. Quit the previous version before replacing it.

Apple Silicon (M1 or later), minimum deployment target macOS 13. Ad hoc signing, without Developer ID or notarization. Display controls and recovery from v0.2.0 are preserved.

## Validation

Tests cover display safeguards, system language resolution, persistence, temporary overrides, and 54 translations with matching format placeholders. Compiled app help and errors checked in both languages. Window verified in English and Spanish without changing display state. Physical monitor behavior and input switching still depend on your setup.

[English guide](../README.en.md) · [Credits](../README.en.md#compatibility-and-credits)
