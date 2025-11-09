#!/bin/bash
# Script to clean and rebuild KelimeVeIslemV1 Xcode project

echo "🧹 Cleaning Xcode build artifacts..."

# Navigate to project directory
cd "$(dirname "$0")"

# 1. Clean build folder
echo "Step 1: Cleaning build folder..."
rm -rf build/
rm -rf DerivedData/

# 2. Clean Xcode derived data (if running on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Step 2: Cleaning Xcode derived data..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/KelimeVeIslemV1-*

    # 3. Clean using xcodebuild
    echo "Step 3: Running xcodebuild clean..."
    xcodebuild clean -project KelimeVeIslemV1.xcodeproj -scheme KelimeVeIslemV1 -configuration Debug

    # 4. Build the project
    echo "Step 4: Building project..."
    xcodebuild build -project KelimeVeIslemV1.xcodeproj -scheme KelimeVeIslemV1 -configuration Debug

    echo "✅ Clean and build complete!"
    echo ""
    echo "If you still see errors in Xcode:"
    echo "1. Restart Xcode"
    echo "2. Open the project"
    echo "3. Product → Clean Build Folder (Shift+Cmd+K)"
    echo "4. Product → Build (Cmd+B)"
else
    echo "⚠️  This script should be run on macOS with Xcode installed"
    echo ""
    echo "Please run these commands in Xcode:"
    echo "1. Product → Clean Build Folder (Shift+Cmd+K)"
    echo "2. Close Xcode"
    echo "3. Delete ~/Library/Developer/Xcode/DerivedData/KelimeVeIslemV1-*"
    echo "4. Reopen Xcode"
    echo "5. Product → Build (Cmd+B)"
fi
