# Vibeviewer DMG Packaging

This document describes how to package Vibeviewer into a DMG file for distribution.

## Quick Start

To create a DMG package, run:

```bash
make dmg
```

Or for a complete release build:

```bash  
make release
```

## Available Make Targets

- `make build` - Build the app in Release configuration
- `make dmg` - Create DMG package (builds app first)
- `make release` - Complete release workflow: clear → generate → build → dmg

## Manual DMG Creation

You can also run the DMG creation script directly:

```bash
./Scripts/create_dmg.sh
```

## Customization

Edit `Scripts/create_dmg.sh` to customize:

- App name and version
- DMG background image
- Build configuration
- Output file name

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Package DMG

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: latest-stable
        
    - name: Create DMG
      run: make release
      
    - name: Upload DMG
      uses: actions/upload-artifact@v4
      with:
        name: Vibeviewer-DMG
        path: "*.dmg"
```

### Fastlane Integration

Add to your `Fastfile`:

```ruby
desc "Build and package DMG"
lane :package_dmg do
  sh("make release")
  
  # Optional: Upload to external service
  # sh("aws s3 cp *.dmg s3://your-bucket/releases/")
end
```

## Output

The DMG creation process will:

1. Clean previous builds
2. Build the app in Release configuration  
3. Create a temporary DMG structure with:
   - Your app
   - Applications folder symlink
   - Optional background image
4. Generate the final DMG file
5. Clean up temporary files

The final DMG will be named `Vibeviewer-1.0.dmg` and placed in the project root.