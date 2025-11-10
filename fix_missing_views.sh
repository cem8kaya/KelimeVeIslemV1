#!/bin/bash

# Script to fix "Cannot find view in scope" errors in Xcode
# This is a common issue caused by stale derived data or indexing problems

echo "🔧 Fixing missing view imports..."
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DERIVED_DATA_DIR="${HOME}/Library/Developer/Xcode/DerivedData"

echo "📁 Project directory: $PROJECT_DIR"
echo ""

# Step 1: Clean the build folder
echo "🧹 Step 1: Cleaning build folder..."
cd "$PROJECT_DIR"
xcodebuild -project KelimeVeIslemV1.xcodeproj -alltargets clean 2>/dev/null || echo "⚠️  xcodebuild clean skipped (not available or failed)"
echo "✅ Build folder cleaned"
echo ""

# Step 2: Delete derived data for this project
echo "🗑️  Step 2: Deleting derived data..."
if [ -d "$DERIVED_DATA_DIR" ]; then
    # Find and remove derived data for this specific project
    find "$DERIVED_DATA_DIR" -name "KelimeVeIslemV1-*" -type d -exec rm -rf {} + 2>/dev/null || true
    echo "✅ Derived data deleted"
else
    echo "ℹ️  Derived data directory not found (this is okay)"
fi
echo ""

# Step 3: Verify file existence
echo "🔍 Step 3: Verifying view files exist..."
VIEW_FILES=(
    "KelimeVeIslemV1/Views/DailyChallenge/DailyChallengeView.swift"
    "KelimeVeIslemV1/Views/Achievements/AchievementsView.swift"
)

all_exist=true
for file in "${VIEW_FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$file" ]; then
        echo "✅ Found: $file"
    else
        echo "❌ Missing: $file"
        all_exist=false
    fi
done
echo ""

if [ "$all_exist" = false ]; then
    echo "❌ Some view files are missing! Please check your project structure."
    exit 1
fi

# Step 4: Build the project to force reindexing
echo "🔨 Step 4: Building project to force reindexing..."
xcodebuild -project KelimeVeIslemV1.xcodeproj -scheme KelimeVeIslemV1 build 2>&1 | tee build.log || true
echo ""

if grep -q "BUILD SUCCEEDED" build.log 2>/dev/null; then
    echo "✅ Build succeeded!"
    rm build.log
elif [ -f build.log ]; then
    echo "⚠️  Build had issues. Check build.log for details."
    echo "Common fixes:"
    echo "  1. Open the project in Xcode"
    echo "  2. Go to Product > Clean Build Folder (Cmd+Shift+K)"
    echo "  3. Close Xcode"
    echo "  4. Delete ~/Library/Developer/Xcode/DerivedData"
    echo "  5. Reopen Xcode and build again"
else
    echo "ℹ️  Could not run build (xcodebuild may not be available)"
    echo ""
    echo "Manual steps to fix in Xcode:"
    echo "  1. Open KelimeVeIslemV1.xcodeproj in Xcode"
    echo "  2. Go to Product > Clean Build Folder (Cmd+Shift+K)"
    echo "  3. Close Xcode completely"
    echo "  4. Delete ~/Library/Developer/Xcode/DerivedData"
    echo "  5. Reopen Xcode"
    echo "  6. Build the project (Cmd+B)"
fi
echo ""

echo "✨ Done! If the issue persists, try the following in Xcode:"
echo ""
echo "Option A - Quick Fix:"
echo "  1. Close Xcode"
echo "  2. Run: rm -rf ~/Library/Developer/Xcode/DerivedData"
echo "  3. Reopen Xcode and build"
echo ""
echo "Option B - Remove and Re-add Files:"
echo "  1. In Xcode, select DailyChallengeView.swift in the project navigator"
echo "  2. Right-click > Delete > Remove Reference"
echo "  3. Repeat for AchievementsView.swift"
echo "  4. Right-click on the appropriate folder > Add Files to 'KelimeVeIslemV1'..."
echo "  5. Select both files and ensure 'Add to targets: KelimeVeIslemV1' is checked"
echo ""
