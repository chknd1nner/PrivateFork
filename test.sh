#!/bin/bash

# PrivateFork Test Suite Runner
# Convenience script for manual test execution during development

echo "🧪 PrivateFork Test Suite Runner"
echo "================================"
echo ""

# Check if we're in the right directory
if [[ ! -d "PrivateFork.xcworkspace" ]]; then
    echo "❌ Error: Must run from PrivateFork project root directory"
    exit 1
fi

echo "📋 Test Plan: PrivateFork/PrivateFork.xctestplan"
echo "🎯 Test Targets:"
echo "   • PrivateForkTests (Unit Tests)"
echo "   • PrivateForkUITests (UI Tests)"
echo "   • PrivateForkFeatureTests (Package Tests)"
echo ""

# Run the test suite
echo "🚀 Executing test suite..."
xcodebuild test -scheme PrivateFork -workspace PrivateFork.xcworkspace

# Report results
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ All tests passed successfully!"
    echo "🎉 Test suite is healthy and ready for development."
else
    echo ""
    echo "❌ Some tests failed."
    echo "🔧 Review the output above to identify and fix issues."
fi