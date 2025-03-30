#!/bin/bash
# Script to manually deploy Flutter web app to GitHub Pages

# Exit on error
set -e

echo "Checking Flutter and Dart versions..."
DART_VERSION=$(dart --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
echo "Dart version: $DART_VERSION"

# Check if Dart version meets the requirement
if [ "$(printf '%s\n' "3.5.4" "$DART_VERSION" | sort -V | head -n1)" != "3.5.4" ]; then
  echo "Error: Dart SDK version 3.5.4 or higher is required."
  echo "Current version: $DART_VERSION"
  echo "Please update your Flutter/Dart SDK and try again."
  exit 1
fi

echo "Building Flutter web app..."
cd dart_rpg
flutter build web --release --base-href /DartRPG/
cd ..

echo "Creating gh-pages branch..."
git checkout --orphan gh-pages-temp

# Remove everything except the build/web directory
find . -maxdepth 1 ! -name . ! -name dart_rpg ! -name .git -exec rm -rf {} \;
find dart_rpg -maxdepth 1 ! -name dart_rpg ! -name build -exec rm -rf {} \;
find dart_rpg/build -maxdepth 1 ! -name build ! -name web -exec rm -rf {} \;

# Move the web build to the root
mv dart_rpg/build/web/* .
rm -rf dart_rpg

# Add all files
git add .
git commit -m "Deploy to GitHub Pages"

# Force push to gh-pages branch
git push -f origin gh-pages-temp:gh-pages

# Return to the original branch
git checkout -

echo "Deployment complete!"
echo "Now go to https://github.com/zombieCraig/DartRPG/settings/pages"
echo "Set the source to 'Deploy from a branch', select 'gh-pages' branch and '/ (root)' folder"
echo "Your app will be available at https://zombiecraig.github.io/DartRPG/"
