# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [Unreleased]

## [0.3.0] - 2026-07-28

### Added

- Added the Reicon icon provider.
- Icon references passed through arbitrary component attributes (e.g. `<.stat_card empty_icon="heroicons:inbox" />`) are now discovered, not just the `name` attribute of icon components.

### Changed

- The test suite now runs fully offline against fixture zips; real provider downloads run in a dedicated, non-blocking CI job (`mix test --include network`).

## [0.2.1] - 2026-06-30

### Fixed

- Support Phoenix LiveView `1.2+` (the HEEx tokenizer module was renamed).
- Icon references in remote component calls (e.g. `<MyApp.Icons.icon name="heroicons:bell" />`) are now discovered. The tokenizer emits the tag name as a plain string, so the previous `{module, function}` tuple match never fired and these calls were silently skipped at compile time — leaving the icons undownloaded in production.
- `download: :all` now fills in icons missing from an existing on-disk set instead of skipping when the directory is non-empty, so switching a provider from a subset (e.g. `{:also, …}`) to `:all` downloads the rest — including with a warm `_build/` cache.
- `__mix_recompile__?/0` now also recompiles when the `:providers` config changes, even if the on-disk icon set is unaffected (the config is read with `Application.get_env`, which the compiler can't track).

## [0.2.0] - 2026-05-08

### Added

- Added `download: {:also, icons}` provider config to download extra configured icons in addition to icons discovered in source files.

### Changed

- Icon downloads now retry on transient failures (HTTP 408, 429, 5xx, and connection errors) with exponential backoff and jitter. Retry count and backoff base are configurable via the `:max_attempts` and `:backoff_base_ms` application env keys.

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
