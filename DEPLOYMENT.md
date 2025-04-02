# Deploying DartRPG to GitHub Pages

This document outlines the process for deploying the DartRPG Flutter web app to GitHub Pages.

## Automatic Deployment with GitHub Actions

The repository is configured with a GitHub Actions workflow that automatically builds and deploys the Flutter web app to GitHub Pages whenever changes are pushed to the `main` branch.

### How It Works

1. When you push changes to the `main` branch, the GitHub Actions workflow is triggered
2. The workflow sets up Flutter, installs dependencies, and builds the web app
3. The built web app is then deployed to the `gh-pages` branch
4. GitHub Pages serves the content from the `gh-pages` branch

### Configuring GitHub Pages

After the first successful workflow run:

1. Go to your repository settings on GitHub: https://github.com/zombieCraig/DartRPG/settings/pages
2. Under "Source", select "Deploy from a branch"
3. Select the `gh-pages` branch and `/ (root)` folder
4. Click "Save"

Your app will be available at: https://zombiecraig.github.io/DartRPG/

## Manual Deployment

If you prefer to deploy manually or need to troubleshoot the deployment process, you can use the provided script:

```bash
./deploy-to-gh-pages.sh
```

This script:
1. Builds the Flutter web app with the correct base-href
2. Creates a temporary branch for deployment
3. Moves the web build to the root of the repository
4. Commits and pushes to the `gh-pages` branch
5. Returns to your original branch

After running the script, follow the same GitHub Pages configuration steps as described above.

## Troubleshooting

### Base Path Issues

If your app loads but shows a blank screen or can't find assets, check the browser console for 404 errors. This might indicate a base path issue. Ensure the `--base-href` parameter in both the GitHub Actions workflow and the manual deployment script matches your repository name: `/DartRPG/`.

### GitHub Pages Not Updating

If your GitHub Pages site isn't reflecting the latest changes:

1. Check the GitHub Actions workflow run for any errors
2. Verify that the `gh-pages` branch has been updated with the latest build
3. Check the GitHub Pages settings to ensure it's configured to deploy from the `gh-pages` branch
4. Be patient, as GitHub Pages can sometimes take a few minutes to update

### Flutter Web Build Issues

If you encounter issues with the Flutter web build:

1. **Flutter Version Requirement**: This project requires Flutter 3.29.2 or higher (with Dart SDK 3.5.4+)
   - Check your Flutter version with `flutter --version`
   - Update Flutter with `flutter upgrade` if needed
   - If you see a Dart SDK version error, make sure you're using Flutter 3.29.2+

2. Try building locally with `flutter build web --release --base-href /DartRPG/`
3. Check for any Flutter web-specific issues in your code
4. Ensure your Flutter version is compatible with web builds

## Customizing the Deployment

### Custom Domain

If you want to use a custom domain:

1. Add your domain in the GitHub Pages settings
2. Update the `--base-href` parameter in both the GitHub Actions workflow and the manual deployment script to `/` instead of `/DartRPG/`
3. Create a `CNAME` file in the `web` directory with your domain name

### Deployment Branch

If you want to use a different branch for deployment:

1. Update the GitHub Actions workflow file (`.github/workflows/flutter-web-deploy.yml`) to use your preferred branch name
2. Update the manual deployment script (`deploy-to-gh-pages.sh`) to push to your preferred branch
3. Update the GitHub Pages settings to deploy from your preferred branch
