# Multi-Platform Release Process for DartRPG

This document explains how to use the GitHub Actions workflow to build and release DartRPG for multiple platforms (Linux, macOS, and Windows).

## Overview

The repository is configured with a GitHub Actions workflow that automatically builds the application for multiple platforms whenever a new GitHub Release is created. The workflow:

1. Builds the application for Linux, macOS, and Windows
2. Automatically updates the version in `pubspec.yaml` to match the release tag
3. Packages the builds appropriately for each platform
4. Uploads the packages as assets to the GitHub release

## Creating a Release

To create a new release and trigger the multi-platform build process:

1. Go to your repository on GitHub: https://github.com/zombieCraig/DartRPG
2. Click on "Releases" in the right sidebar
3. Click "Create a new release"
4. Enter a tag version (e.g., `v1.2.3`)
   - **Important**: The tag must start with `v` (e.g., `v1.2.3`, not `1.2.3`)
5. Add a title and description for your release
6. Click "Publish release"

## Automated Process

Once you create a release, the following happens automatically:

1. The GitHub Actions workflow is triggered
2. The version in `pubspec.yaml` is updated to match your release tag
3. The changelog.json file is updated with the new version and changes from memory-bank files
4. The application is built for Linux, macOS, and Windows
5. The builds are packaged as:
   - Linux: `.tar.gz` archive
   - macOS: `.zip` archive
   - Windows: `.zip` archive
6. The packages are uploaded as assets to your GitHub release
7. The release description is updated with the changelog content

## Checking Build Status

To check the status of your builds:

1. Go to your repository on GitHub
2. Click on "Actions" in the top navigation
3. Click on the "Multi-Platform Release" workflow
4. Click on the latest run to see details

If a build fails, you can see the error logs and make necessary fixes before creating a new release.

## Release Assets

After the workflow completes successfully, your GitHub release will have the following assets:

- `dart_rpg-Linux-x.y.z.tar.gz`: Linux build
- `dart_rpg-macOS-x.y.z.zip`: macOS build
- `dart_rpg-Windows-x.y.z.zip`: Windows build

Where `x.y.z` is the version number from your release tag.

## Version Management

The workflow automatically updates the version in `pubspec.yaml` and the changelog:

- The version string is extracted from the tag (e.g., `v1.2.3` becomes `1.2.3`)
- The build number is set to the GitHub run number for uniqueness
- The resulting version in `pubspec.yaml` will be something like `1.2.3+123`
- The changelog.json file is updated with the new version and changes from memory-bank files
- The app's About section and changelog screen will automatically display the correct version

## Recent Workflow Updates

The multi-platform release workflow has been updated to address several issues:

1. **Deprecated GitHub Actions Commands**: 
   - Replaced the deprecated `actions/upload-release-asset@v1` action with the modern `softprops/action-gh-release@v1`
   - This resolves the warning about the deprecated `set-output` command

2. **Windows Build Path Fix**:
   - Updated the Windows build path to include the `x64` directory: `build/windows/x64/runner/Release`
   - Added directory verification to provide better error messages if the path is incorrect
   - Added directory listing to help diagnose path issues

3. **macOS Build Verification**:
   - Added file existence verification after creating the macOS zip file
   - Improved error reporting for macOS packaging

4. **Cross-Platform Shell Compatibility**:
   - Added explicit shell specification for version extraction step
   - Ensures bash is used on all platforms including Windows
   - Fixes PowerShell compatibility issues with bash syntax

## Troubleshooting

### Build Failures

If a build fails:

1. Check the error logs in the GitHub Actions workflow run
2. Make necessary fixes to your code
3. Create a new release with a new tag

### Missing Dependencies

If builds fail due to missing dependencies:

- For Linux: Check the "Linux setup" step in the workflow
- For macOS: Check the "macOS setup" step in the workflow
- For Windows: Ensure all required dependencies are installed

### Path Issues

If builds fail due to path issues:

- For Windows: Check the "Package application" step logs for the directory listing
- For macOS: Check the "Package application" step logs for file verification
- Verify that the build paths in the workflow match the actual output paths of your Flutter build

### Version Issues

If the version isn't updating correctly:

- Ensure your tag starts with `v` (e.g., `v1.2.3`)
- Check the "Update pubspec version" step in the workflow logs

## Changelog Integration

The release process now includes automated changelog generation:

1. The changelog is maintained in `dart_rpg/assets/data/changelog.json`
2. A Python script (`scripts/update_changelog.py`) extracts changes from memory-bank files
3. The GitHub Actions workflow automatically includes the changelog in the release description

### Using the Changelog Script

You can use the changelog script manually to:

- Update the changelog with changes from memory-bank files:
  ```bash
  python3 scripts/update_changelog.py <version>
  ```

- Extract changelog content for a specific version:
  ```bash
  python3 scripts/update_changelog.py <version> --extract-only
  ```

### In-App Changelog

The app includes a changelog screen accessible from the About section in Settings. This screen displays all version history with changes in a user-friendly format.

## Future Enhancements

Potential future enhancements to the release process:

- Code signing for macOS and Windows builds
- Creating proper installers for each platform
- Notarization for macOS builds
- Improved error handling and reporting
- Build caching to speed up the process
