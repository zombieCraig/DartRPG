#!/bin/bash
# Script to manually deploy Flutter web app to GitHub Pages

# Exit on error
set -e

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
