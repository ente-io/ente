#!/bin/bash

# Dependency Parser for Mobile Packages
#
# Parses pubspec.yaml files to build a dependency graph and determines
# which packages/apps need to be linted based on what changed.
#
# Usage:
#   ./get-affected-packages.sh <changed_file1> <changed_file2> ...
#
# Output (JSON to stdout):
#   {
#     "packages": "pkg1 pkg2 pkg3",
#     "lint_photos": "true/false",
#     "lint_auth": "true/false",
#     "lint_locker": "true/false",
#     "lint_all": "true/false"
#   }

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/../.."
PACKAGES_DIR="$REPO_ROOT/mobile/packages"
APPS_DIR="$REPO_ROOT/mobile/apps"

# Parse local dependencies from a pubspec.yaml file
# Returns space-separated list of package names
parse_dependencies() {
    local pubspec_file=$1

    if [ ! -f "$pubspec_file" ]; then
        echo ""
        return
    fi

    # Extract dependencies with "path: ../" pattern
    # Handle both "../packagename" and "../../packages/packagename"
    grep "path:.*\.\./" "$pubspec_file" 2>/dev/null | \
        sed 's/.*path: *//' | \
        sed 's/[[:space:]]*$//' | \
        sed 's/.*\///' | \
        tr '\n' ' ' || echo ""
}

# Build dependency graph
# Format: package_name:dep1,dep2,dep3
build_dep_graph() {
    local graph=""

    for pkg_dir in "$PACKAGES_DIR"/*/ ; do
        if [ ! -d "$pkg_dir" ]; then
            continue
        fi

        pkg_name=$(basename "$pkg_dir")

        # Skip rust package (handled separately)
        if [ "$pkg_name" = "rust" ]; then
            continue
        fi

        pubspec="$pkg_dir/pubspec.yaml"
        deps=$(parse_dependencies "$pubspec")

        # Convert space-separated to comma-separated
        deps_csv=$(echo "$deps" | tr ' ' ',')
        graph="$graph$pkg_name:$deps_csv"$'\n'
    done

    echo "$graph"
}

# Get packages that depend on a given package
get_dependents() {
    local target_pkg=$1
    local dep_graph=$2
    local dependents=""

    while IFS=: read -r pkg deps; do
        if [ -z "$pkg" ]; then
            continue
        fi

        # Check if target_pkg is in deps
        if echo ",$deps," | grep -q ",$target_pkg,"; then
            dependents="$dependents $pkg"
        fi
    done <<< "$dep_graph"

    echo "$dependents"
}

# Get all affected packages (transitive)
get_affected_packages() {
    local changed_pkgs=$1
    local dep_graph=$2

    local affected="$changed_pkgs"
    local to_process="$changed_pkgs"

    # Iteratively find all dependents
    for _ in {1..10}; do  # Max 10 levels of dependency
        local new_deps=""

        for pkg in $to_process; do
            local deps=$(get_dependents "$pkg" "$dep_graph")
            for dep in $deps; do
                # Add if not already in affected
                if ! echo " $affected " | grep -q " $dep "; then
                    affected="$affected $dep"
                    new_deps="$new_deps $dep"
                fi
            done
        done

        if [ -z "$new_deps" ]; then
            break
        fi

        to_process="$new_deps"
    done

    # Sort and deduplicate
    echo "$affected" | tr ' ' '\n' | sort -u | tr '\n' ' '
}

# Check if app depends on any of the affected packages
check_app_affected() {
    local app_name=$1
    local affected_pkgs=$2

    local app_pubspec="$APPS_DIR/$app_name/pubspec.yaml"
    local app_deps=$(parse_dependencies "$app_pubspec")

    for pkg in $affected_pkgs; do
        if echo " $app_deps " | grep -q " $pkg "; then
            echo "true"
            return
        fi
    done

    echo "false"
}

# Main logic
main() {
    local changed_files=("$@")

    # Safety checks: lint everything if certain files changed
    local lint_all="false"

    if [ ${#changed_files[@]} -eq 0 ]; then
        lint_all="true"
    fi

    for file in "${changed_files[@]}"; do
        if [[ "$file" == *".github/workflows/mobile-packages-lint.yml"* ]] || \
           [[ "$file" == *"mobile/analysis_options.yaml"* ]] || \
           [[ "$file" == *"pubspec.yaml"* ]]; then
            lint_all="true"
            break
        fi
    done

    # If linting all, return all packages
    if [ "$lint_all" = "true" ]; then
        local all_pkgs=$(find "$PACKAGES_DIR" -maxdepth 1 -type d -not -name "packages" -not -name "rust" -exec basename {} \; | sort | tr '\n' ' ')

        echo "{"
        echo "  \"packages\": \"$all_pkgs\","
        echo "  \"lint_photos\": \"true\","
        echo "  \"lint_auth\": \"true\","
        echo "  \"lint_locker\": \"true\","
        echo "  \"lint_all\": \"true\""
        echo "}"
        return
    fi

    # Extract changed package names
    local changed_pkgs=""
    for file in "${changed_files[@]}"; do
        if [[ "$file" =~ mobile/packages/([^/]+)/ ]]; then
            pkg_name="${BASH_REMATCH[1]}"
            if [ "$pkg_name" != "rust" ]; then
                if ! echo " $changed_pkgs " | grep -q " $pkg_name "; then
                    changed_pkgs="$changed_pkgs $pkg_name"
                fi
            fi
        fi
    done

    # If no packages changed, nothing to lint
    if [ -z "$(echo $changed_pkgs | tr -d ' ')" ]; then
        echo "{"
        echo "  \"packages\": \"\","
        echo "  \"lint_photos\": \"false\","
        echo "  \"lint_auth\": \"false\","
        echo "  \"lint_locker\": \"false\","
        echo "  \"lint_all\": \"false\""
        echo "}"
        return
    fi

    # Build dependency graph
    local dep_graph=$(build_dep_graph)

    # Get all affected packages
    local affected_pkgs=$(get_affected_packages "$changed_pkgs" "$dep_graph")

    # Check which apps are affected
    local lint_photos=$(check_app_affected "photos" "$affected_pkgs")
    local lint_auth=$(check_app_affected "auth" "$affected_pkgs")
    local lint_locker=$(check_app_affected "locker" "$affected_pkgs")

    # Output JSON
    echo "{"
    echo "  \"packages\": \"$affected_pkgs\","
    echo "  \"lint_photos\": \"$lint_photos\","
    echo "  \"lint_auth\": \"$lint_auth\","
    echo "  \"lint_locker\": \"$lint_locker\","
    echo "  \"lint_all\": \"false\""
    echo "}"
}

main "$@"
