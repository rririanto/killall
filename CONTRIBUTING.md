# Contributing to QuiteAll

Thank you for your interest in contributing to QuiteAll! We welcome bug fixes, documentation improvements, architectural enhancements, and feature requests.

## Architecture Philosophy

QuiteAll is built on three core pillars:
1. **Zero Bloat & Zero Telemetry**: Absolutely no third-party tracking, analytics, DRM, or background metric drain.
2. **Native Performance**: Pure Swift 6 + SwiftUI using direct Darwin `libproc` (`proc_pidinfo`) APIs for lightweight, instantaneous execution (<15MB RAM footprint).
3. **Safety & Non-Destructive Protection**: Critical system services and user-protected apps must always remain safeguarded against bulk termination.

## Development Workflow

### Prerequisites
- macOS 13.0 (Ventura) or newer
- Xcode 15.0+ or Swift 5.9+ / Swift 6.0 toolchain

### Building & Running
Clone the repository:
```bash
git clone https://github.com/rririanto/quiteall.git
cd quiteall
```

Run tests via Swift Package Manager:
```bash
swift test
```

Build the release application bundle:
```bash
./scripts/build_app.sh
```

### Testing Guidelines
- All new features and bug fixes should follow test-driven patterns where feasible.
- Tests live in `Tests/QuiteAllTests/`.
- Run `swift test` before submitting a pull request to ensure all tests pass.

### Pull Request Process
1. Fork the repo and create a feature branch (`git checkout -b feature/my-feature`).
2. Commit your changes with clear, descriptive commit messages adhering to Conventional Commits (e.g. `feat:`, `fix:`, `docs:`, `refactor:`).
3. Ensure no proprietary, copyrighted, or unlicensed binary assets (icons, sounds, frameworks) are introduced.
4. Push to your branch and open a Pull Request against `main`.

## Code of Conduct
Please adhere to our [Code of Conduct](CODE_OF_CONDUCT.md) in all community interactions.
