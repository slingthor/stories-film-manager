#!/bin/bash

# Script to increment app data version on each build
# This should be added as a Build Phase in Xcode

APPDATA_BASE="/Users/ingthor/Documents/stories/appdata"
JSON_DIR="$APPDATA_BASE/json"
RESOURCES_BASE="/Users/ingthor/Documents/stories/App/App/FilmManager/Resources"

# Create base directories if they don't exist
mkdir -p "$JSON_DIR"
mkdir -p "$APPDATA_BASE/resources"

# Find the highest version number
HIGHEST_VERSION=0
for dir in "$JSON_DIR"/*; do
    if [ -d "$dir" ]; then
        dirname=$(basename "$dir")
        if [[ "$dirname" =~ ^[0-9]+$ ]]; then
            if [ "$dirname" -gt "$HIGHEST_VERSION" ]; then
                HIGHEST_VERSION="$dirname"
            fi
        fi
    fi
done

# Check if we need a new version (always create new version on build)
NEW_VERSION=$((HIGHEST_VERSION + 1))
NEW_VERSION_DIR="$JSON_DIR/$NEW_VERSION"
OLD_VERSION_DIR="$JSON_DIR/$HIGHEST_VERSION"

echo "Creating new version: $NEW_VERSION"

# Create new version directory
mkdir -p "$NEW_VERSION_DIR/shots"

# Copy from previous version if it exists
if [ "$HIGHEST_VERSION" -gt 0 ] && [ -d "$OLD_VERSION_DIR" ]; then
    echo "Copying from version $HIGHEST_VERSION to version $NEW_VERSION"
    
    # Copy all files from old version
    cp -r "$OLD_VERSION_DIR"/* "$NEW_VERSION_DIR/" 2>/dev/null || true
fi

# Update with latest resource files
echo "Updating resource files from app bundle"

# Copy resource JSON files
for file in "environmental_plates_index.json" "character_plates_index.json" "shot_plate_recommendations.json" "main_film_system.json"; do
    if [ -f "$RESOURCES_BASE/$file" ]; then
        cp "$RESOURCES_BASE/$file" "$NEW_VERSION_DIR/"
        echo "  Updated $file"
    fi
done

# Copy new shot files (only if they don't exist)
if [ -d "$RESOURCES_BASE/shots" ]; then
    for shot in "$RESOURCES_BASE/shots"/*.json; do
        if [ -f "$shot" ]; then
            filename=$(basename "$shot")
            if [ ! -f "$NEW_VERSION_DIR/shots/$filename" ]; then
                cp "$shot" "$NEW_VERSION_DIR/shots/"
                echo "  Added new shot: $filename"
            fi
        fi
    done
fi

# Create build marker
touch "$NEW_VERSION_DIR/.build_marker"

echo "Version $NEW_VERSION created successfully"
echo "Path: $NEW_VERSION_DIR"

# Export the version for use in Info.plist or elsewhere
echo "$NEW_VERSION" > "$APPDATA_BASE/current_version.txt"