#!/bin/bash

# Comprehensive linter test script for all mobile packages and apps
# This script runs flutter analyze on all packages and apps to catch issues before CI

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

total_packages=0
failed_packages=0
total_warnings=0
total_errors=0
failed_list=()

echo "================================================"
echo "Testing Mobile Packages Linter"
echo "================================================"
echo ""

# Function to test a package
test_package() {
    local pkg_path=$1
    local pkg_name=$(basename "$pkg_path")

    echo -n "Testing $pkg_name... "

    cd "$pkg_path"

    # Run pub get silently
    flutter pub get > /dev/null 2>&1

    # Run analyze and capture output
    output=$(flutter analyze --no-fatal-infos 2>&1)
    warnings=$(echo "$output" | grep -c "warning •" || true)
    errors=$(echo "$output" | grep -c "error •" || true)

    total_packages=$((total_packages + 1))
    total_warnings=$((total_warnings + warnings))
    total_errors=$((total_errors + errors))

    if [ "$warnings" -gt 0 ] || [ "$errors" -gt 0 ]; then
        echo -e "${RED}FAILED${NC} ($errors errors, $warnings warnings)"
        failed_packages=$((failed_packages + 1))
        failed_list+=("$pkg_name")
        echo "$output" | grep -E "warning •|error •"
        echo ""
    else
        echo -e "${GREEN}PASSED${NC}"
    fi

    cd - > /dev/null
}

# Test all packages
echo "=== Testing Packages ==="
for pkg in mobile/packages/*/; do
    # Skip if not a directory or if it's a hidden directory
    if [ ! -d "$pkg" ] || [[ $(basename "$pkg") == .* ]]; then
        continue
    fi

    # Skip rust package (tested separately)
    if [[ $(basename "$pkg") == "rust" ]]; then
        continue
    fi

    test_package "$pkg"
done

echo ""
echo "=== Testing Apps ==="

# Test photos app
test_package "mobile/apps/photos"

# Test auth app
test_package "mobile/apps/auth"

# Test locker app
test_package "mobile/apps/locker"

echo ""
echo "================================================"
echo "Summary"
echo "================================================"
echo "Total packages/apps tested: $total_packages"
echo "Total errors: $total_errors"
echo "Total warnings: $total_warnings"

if [ "$failed_packages" -gt 0 ]; then
    echo -e "${RED}Failed packages/apps: $failed_packages${NC}"
    echo "Failed list:"
    for pkg in "${failed_list[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    echo -e "${RED}❌ LINTER CHECKS FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}✅ ALL LINTER CHECKS PASSED${NC}"
    exit 0
fi
