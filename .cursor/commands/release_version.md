# Release Version Command

## Description
Automatically bump version number, build DMG package, create GitHub PR and release with English descriptions.

## Usage
```
@release_version [version_type]
```

## Parameters
- `version_type` (optional): Type of version bump
  - `patch` (default): 1.1.1 → 1.1.2
  - `minor`: 1.1.1 → 1.2.0
  - `major`: 1.1.1 → 2.0.0

## Examples
```
@release_version
@release_version patch
@release_version minor
@release_version major
```

## What it does
1. **Version Bump**: Updates version in `Scripts/create_dmg.sh` and `Derived/InfoPlists/Vibeviewer-Info.plist`
2. **Build DMG**: Runs `make dmg` to create installation package
3. **Git Operations**: Commits changes and pushes to current branch
4. **Create PR**: Creates GitHub PR with English description
5. **Create Release**: Creates GitHub release with DMG attachment and English release notes

## Prerequisites
- GitHub CLI (`gh`) installed and authenticated
- Current branch pushed to remote
- Make sure you're in the project root directory

## Output
- Updated version files
- Built DMG package
- GitHub PR link
- GitHub Release link

## Notes
- The command will automatically detect the current version and increment accordingly
- All descriptions will be in English
- The DMG file will be automatically attached to the release
- Make sure you have write permissions to the repository
