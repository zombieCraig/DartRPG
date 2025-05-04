#!/usr/bin/env python3
import re
import json
import os
import sys
import argparse
from datetime import datetime
from collections import defaultdict

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

def summarize_changes(changes):
    """Summarize changes by grouping related items and creating concise descriptions."""
    if not changes:
        return ["Maintenance update"]
    
    # Clean up changes - remove checkmarks and detailed sub-bullets
    cleaned_changes = []
    for change in changes:
        # Remove checkmarks
        change = re.sub(r'✅\s*', '', change)
        
        # Extract just the main part before any colon or detailed list
        main_part = re.split(r':|with \d+ sub-components', change)[0].strip()
        
        # If it's too long, try to get just the first sentence
        if len(main_part) > 100:
            sentence_match = re.match(r'^([^\.]+)\.', main_part)
            if sentence_match:
                main_part = sentence_match.group(1).strip()
        
        # Remove any remaining markdown formatting
        main_part = re.sub(r'`([^`]+)`', r'\1', main_part)
        
        if main_part and main_part not in cleaned_changes:
            cleaned_changes.append(main_part)
    
    # Define categories and their keywords
    categories = {
        "Features": ["Implement", "Add", "Create", "Develop", "Introduce"],
        "Improvements": ["Enhance", "Improve", "Optimize", "Refactor", "Restructure", "Modularize"],
        "Bug Fixes": ["Fix", "Resolve", "Address", "Correct", "Update"]
    }
    
    # Group changes by category
    categorized_changes = defaultdict(list)
    uncategorized = []
    
    for change in cleaned_changes:
        categorized = False
        for category, keywords in categories.items():
            for keyword in keywords:
                if change.startswith(keyword) or f" {keyword.lower()} " in change.lower():
                    categorized_changes[category].append(change)
                    categorized = True
                    break
            if categorized:
                break
        
        if not categorized:
            uncategorized.append(change)
    
    # Add uncategorized changes to a default category
    if uncategorized:
        categorized_changes["Other Improvements"].extend(uncategorized)
    
    # Group related changes within each category
    summarized_changes = []
    
    # Function to find related changes
    def find_related_changes(changes, main_topic):
        related = []
        remaining = []
        main_words = set(re.findall(r'\b\w+\b', main_topic.lower()))
        
        for change in changes:
            change_words = set(re.findall(r'\b\w+\b', change.lower()))
            # If there's significant word overlap or the change contains the main topic
            if len(main_words.intersection(change_words)) >= 2 or main_topic.lower() in change.lower():
                related.append(change)
            else:
                remaining.append(change)
        
        return related, remaining
    
    # Process each category
    for category, changes_list in categorized_changes.items():
        # Skip empty categories
        if not changes_list:
            continue
            
        processed_changes = []
        remaining_changes = changes_list.copy()
        
        # Process until all changes are handled
        while remaining_changes:
            main_change = remaining_changes.pop(0)
            related_changes, remaining_changes = find_related_changes(remaining_changes, main_change)
            
            if related_changes:
                # Create a summary for the main change and its related changes
                if len(related_changes) > 2:
                    # Extract the main component or feature being changed
                    match = re.search(r'(?:Implement|Add|Create|Enhance|Improve|Fix|Update|Restructure)\w* (?:a |the )?([^:]+)', main_change)
                    if match:
                        feature = match.group(1).strip()
                        summary = f"{main_change} with {len(related_changes)} related improvements"
                    else:
                        summary = f"{main_change} and {len(related_changes)} related improvements"
                else:
                    # For just a couple related changes, be more specific
                    related_text = ", ".join(related_changes)
                    # If the combined text is too long, simplify
                    if len(main_change) + len(related_text) > 100:
                        summary = f"{main_change} and related improvements"
                    else:
                        summary = f"{main_change} and {related_text}"
                
                processed_changes.append(summary)
            else:
                processed_changes.append(main_change)
        
        # Add category header and changes to the final list
        if processed_changes:
            summarized_changes.append(f"**{category}**")
            summarized_changes.extend(processed_changes)
    
    # Limit to a reasonable number of entries (max 15)
    if len(summarized_changes) > 15:
        # Keep category headers and reduce entries proportionally
        headers = [item for item in summarized_changes if item.startswith('**')]
        entries = [item for item in summarized_changes if not item.startswith('**')]
        
        # Calculate how many entries to keep per category
        entries_per_category = max(1, 15 // len(headers))
        
        # Rebuild the summarized changes list
        final_changes = []
        current_category = None
        category_count = 0
        
        for item in summarized_changes:
            if item.startswith('**'):
                if current_category:
                    # Add a "and X more improvements" entry if we truncated items
                    remaining = len([e for e in entries if current_category in e])
                    if remaining > 0:
                        final_changes.append(f"...and {remaining} more improvements")
                
                current_category = item[2:-2]  # Extract category name
                category_count = 0
                final_changes.append(item)
            elif category_count < entries_per_category:
                final_changes.append(item)
                category_count += 1
        
        summarized_changes = final_changes
    
    return summarized_changes

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
    
    # Summarize the changes
    summarized_changes = summarize_changes(changes)
    
    # Add new version
    today = datetime.now().strftime('%Y-%m-%d')
    new_version = {
        "version": version,
        "date": today,
        "changes": summarized_changes
    }
    
    changelog["versions"].insert(0, new_version)  # Add at the beginning
    
    # Write updated changelog
    with open(changelog_path, 'w') as f:
        json.dump(changelog, f, indent=2)
    
    print(f"Updated changelog with {len(summarized_changes)} changes for version {version}")

def show_detailed_help():
    """Display detailed information about how the script works."""
    help_text = """
DETAILED INFORMATION

This script automates the process of updating the changelog.json file with changes
extracted from memory-bank files. It performs the following steps:

1. Extracts recent changes from:
   - memory-bank/activeContext.md (from the "Recent Changes" section)
   - memory-bank/progress.md (from the "Recently Completed" section)

2. Processes and summarizes these changes:
   - Categorizes changes into Features, Improvements, Bug Fixes, etc.
   - Groups related changes together
   - Formats them for the changelog

3. Updates the changelog.json file:
   - Located at dart_rpg/assets/data/changelog.json
   - Adds a new version entry with the current date
   - Preserves existing changelog entries

4. Can also extract formatted changelog content for GitHub release descriptions

The script looks for completed items marked with checkmarks (✅) in the memory-bank
files and processes them into a structured changelog format.
"""
    print(help_text)

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
                
                # Group by categories
                current_category = None
                for change in v["changes"]:
                    if change.startswith("**") and change.endswith("**"):
                        # This is a category header
                        current_category = change[2:-2]  # Remove ** from both ends
                        content += f"### {current_category}\n"
                    else:
                        content += f"- {change}\n"
                
                return content
        
        return f"## Version {version}\n\nNo changelog entries found for this version."
    except Exception as e:
        return f"## Version {version}\n\nError extracting changelog: {e}"

def main():
    """Main function to handle command line arguments and execute the script."""
    parser = argparse.ArgumentParser(
        description="Update the changelog.json file with changes extracted from memory-bank files.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Update changelog with version 1.2.0
  python update_changelog.py 1.2.0
  
  # Extract changelog for version 1.2.0 (for GitHub release)
  python update_changelog.py 1.2.0 --extract-only
  
  # Show what would be added without updating the file
  python update_changelog.py 1.2.0 --dry-run
  
  # Show detailed information about how the script works
  python update_changelog.py --info
  
  # Show this help message
  python update_changelog.py --help
        """
    )
    
    # Add an optional group for the info flag
    info_group = parser.add_mutually_exclusive_group()
    info_group.add_argument(
        "--info",
        action="store_true",
        help="Display detailed information about how the script works"
    )
    
    # Make version optional if --info is used
    parser.add_argument(
        "version", 
        nargs="?",  # Make it optional
        help="Version number to use for the changelog entry (e.g., 1.2.0)"
    )
    
    parser.add_argument(
        "--extract-only", 
        action="store_true",
        help="Extract and print the changelog for the specified version (for GitHub release descriptions)"
    )
    
    parser.add_argument(
        "--dry-run", 
        action="store_true",
        help="Process changes but don't write to changelog.json file"
    )
    
    args = parser.parse_args()
    
    # Handle the info flag first
    if args.info:
        show_detailed_help()
        return
    
    # Check if version is provided for other operations
    if not args.version:
        parser.error("the following arguments are required: version")
    
    if args.extract_only:
        # Just extract and print the changelog for the release description
        print(extract_changelog_for_release(args.version))
    else:
        # Update the changelog with new changes
        changes = extract_changes_from_memory_bank()
        
        if not changes:
            print("No changes found in memory-bank files")
            # Create a minimal change entry instead of exiting with error
            changes = ["Maintenance update"]
        
        if args.dry_run:
            # Just show what would be added without updating the file
            summarized_changes = summarize_changes(changes)
            print(f"Would update changelog with {len(summarized_changes)} changes for version {args.version}:")
            for change in summarized_changes:
                print(f"  {change}")
        else:
            update_changelog(changes, args.version)

if __name__ == "__main__":
    main()
