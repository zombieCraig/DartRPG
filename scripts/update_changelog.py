#!/usr/bin/env python3
import re
import json
import os
import sys
from datetime import datetime

def extract_changes_from_memory_bank():
    """Extract recent changes from memory-bank files."""
    changes = []
    
    # Extract from activeContext.md
    try:
        with open('memory-bank/activeContext.md', 'r') as f:
            content = f.read()
            
        # Find the Recent Changes section
        recent_changes_match = re.search(r'## Recent Changes\s+(.+?)(?=##|\Z)', content, re.DOTALL)
        if recent_changes_match:
            recent_changes = recent_changes_match.group(1)
            # Extract bullet points
            bullets = re.findall(r'- ✅ (.+?)(?=\n- |\n\n|\Z)', recent_changes, re.DOTALL)
            for bullet in bullets:
                # Clean up and format as one-line
                clean_bullet = re.sub(r'\s+', ' ', bullet.strip())
                # Remove any sub-bullets
                clean_bullet = re.sub(r'  - .*', '', clean_bullet)
                if clean_bullet:
                    changes.append(clean_bullet)
    except Exception as e:
        print(f"Error extracting changes from activeContext.md: {e}")
    
    # Extract from progress.md
    try:
        with open('memory-bank/progress.md', 'r') as f:
            content = f.read()
            
        # Find the Recently Completed section
        recent_completed_match = re.search(r'### Recently Completed\s+(.+?)(?=###|\Z)', content, re.DOTALL)
        if recent_completed_match:
            recent_completed = recent_completed_match.group(1)
            # Extract bullet points
            bullets = re.findall(r'- ✅ (.+?)(?=\n- |\n\n|\Z)', recent_completed, re.DOTALL)
            for bullet in bullets:
                # Clean up and format as one-line
                clean_bullet = re.sub(r'\s+', ' ', bullet.strip())
                # Remove any sub-bullets
                clean_bullet = re.sub(r'  - .*', '', clean_bullet)
                if clean_bullet and clean_bullet not in changes:
                    changes.append(clean_bullet)
    except Exception as e:
        print(f"Error extracting changes from progress.md: {e}")
    
    return changes

def update_changelog(changes, version):
    """Update the changelog.json file with new changes."""
    changelog_path = 'dart_rpg/assets/data/changelog.json'
    
    # Create directory if it doesn't exist
    os.makedirs(os.path.dirname(changelog_path), exist_ok=True)
    
    # Load existing changelog or create new one
    if os.path.exists(changelog_path):
        with open(changelog_path, 'r') as f:
            try:
                changelog = json.load(f)
            except json.JSONDecodeError:
                changelog = {"versions": []}
    else:
        changelog = {"versions": []}
    
    # Check if version already exists
    for v in changelog["versions"]:
        if v["version"] == version:
            print(f"Version {version} already exists in changelog")
            return
    
    # Add new version
    today = datetime.now().strftime('%Y-%m-%d')
    new_version = {
        "version": version,
        "date": today,
        "changes": changes
    }
    
    changelog["versions"].insert(0, new_version)  # Add at the beginning
    
    # Write updated changelog
    with open(changelog_path, 'w') as f:
        json.dump(changelog, f, indent=2)
    
    print(f"Updated changelog with {len(changes)} changes for version {version}")

def extract_changelog_for_release(version):
    """Extract changelog content for GitHub release description."""
    changelog_path = 'dart_rpg/assets/data/changelog.json'
    
    if not os.path.exists(changelog_path):
        return f"## Version {version}\n\nNo changelog entries found."
    
    try:
        with open(changelog_path, 'r') as f:
            changelog = json.load(f)
        
        for v in changelog["versions"]:
            if v["version"] == version:
                content = f"## Version {version} ({v['date']})\n\n"
                for change in v["changes"]:
                    content += f"- {change}\n"
                return content
        
        return f"## Version {version}\n\nNo changelog entries found for this version."
    except Exception as e:
        return f"## Version {version}\n\nError extracting changelog: {e}"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: update_changelog.py <version> [--extract-only]")
        sys.exit(1)
    
    version = sys.argv[1]
    extract_only = len(sys.argv) > 2 and sys.argv[2] == "--extract-only"
    
    if extract_only:
        # Just extract and print the changelog for the release description
        print(extract_changelog_for_release(version))
    else:
        # Update the changelog with new changes
        changes = extract_changes_from_memory_bank()
        
        if not changes:
            print("No changes found in memory-bank files")
            sys.exit(1)
        
        update_changelog(changes, version)
