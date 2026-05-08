# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## Unreleased

### Added

- Added `download: {:also, icons}` provider config to download extra configured icons in addition to icons discovered in source files.

## [0.1.1] - 2026-04-28

### Added

- Added regression tests covering recompilation when new icon references are introduced in source files.

### Changed

- `__mix_recompile__?/0` now re-runs icon discovery so adding a new icon reference in source files triggers download and recompilation correctly, including with a warm `_build/` cache.
- Refactored icon discovery to accept a configurable scan root, which makes the source-scanning path testable in isolation.

### Fixed

- Fixed icon scanning behavior on Phoenix LiveView `0.20`.
- Fixed cases where newly added icon references in source files were not picked up until a manual clean rebuild.

## [0.1.0] - 2026-04-28

### Added

- Initial public release of `phx_icons`.
- Compile-time icon discovery, download, and SVG inlining for Phoenix LiveView.
- Built-in providers for Heroicons, Lucide, Tabler, Phosphor, Simple Icons, Flagpack, and Lineicons.
- Custom provider support via the `PhxIcons.Provider` behaviour.
