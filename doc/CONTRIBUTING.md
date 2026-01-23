# Contributing to Spotikit

> **Version 1.0.0** - First stable release

Thanks for your interest in contributing! This guide explains the preferred workflow.

## Development Environment
- Flutter (stable channel) >= 3.3
- Dart SDK per `pubspec.yaml`
- Android SDK / Emulator or physical device

## Workflow
1. Fork repository
2. Create a feature branch: `feat/<short-description>`
3. Implement changes + update/add docs under `doc/` or README sections
4. Update example app if the API surface changes
5. Run analyzer & format
6. Test example manually on device/emulator
7. Open PR with clear description & before/after notes

## Code Style
- Follow `flutter_lints`
- Prefer small, composable methods
- Avoid over-abstracting prematurely
- Keep public API additions documented

## Commits
- Use conventional style where possible (e.g., `feat: add playback state stream`)
- Squash if many WIP commits

## Versioning
- Maintainers will bump version & update CHANGELOG on merge

## Testing
Currently manual example testing; future roadmap includes unit tests for:
- Model parsing
- Auth state stream
- Playback state mapping

## Issues
When filing, include:
- Plugin version
- Platform & device
- Reproduction steps
- Logs (with sensitive data redacted)

## Security
Do not include real client secrets in issues or code. Use placeholders.

## License
By contributing you agree your work is licensed under the MIT license used by this project.

Happy hacking!

