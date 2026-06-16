#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

fail() {
    echo "prepare_fdroid_source: $*" >&2
    exit 1
}

remove_direct_dependencies() {
    local count
    count=$(rg -c "^  (firebase_core|firebase_messaging|in_app_purchase):" pubspec.yaml || true)
    [[ "$count" == "3" ]] || fail "expected three restricted dependencies in pubspec.yaml"
    perl -0pi -e 's/^  (firebase_core|firebase_messaging|in_app_purchase):[^\n]*\n//mg' pubspec.yaml

    count=$(rg -c "^[[:space:]]*playstoreImplementation ['\"]com\\.android\\.installreferrer:installreferrer:" android/app/build.gradle || true)
    [[ "$count" == "1" ]] || fail "expected one Play install referrer dependency in android/app/build.gradle"
    perl -0pi -e 's/^[[:space:]]*playstoreImplementation ['\''"]com\.android\.installreferrer:installreferrer:[^'\''"]+['\''"]\n//mg' android/app/build.gradle
}

remove_playstore_sources() {
    rm -rf android/app/src/playstore/kotlin
}

copy_fdroid_overlay() {
    cp -R fdroid/overlay/lib/. lib/
}

assert_fdroid_source() {
    if rg -n "package:(firebase_core|firebase_messaging|in_app_purchase)" lib pubspec.yaml; then
        fail "restricted package imports or direct dependencies remain"
    fi

    if rg -n "FirebaseMessaging|Firebase\\.initializeApp|RemoteMessage|InAppPurchase|PurchaseStatus" lib; then
        fail "restricted Firebase or in-app purchase references remain"
    fi

    if rg -n "com\\.android\\.installreferrer|InstallReferrer(Client|StateListener)|installreferrer" android/app/build.gradle android/app/src; then
        fail "Play install referrer dependency or source remains"
    fi
}

remove_direct_dependencies
remove_playstore_sources
copy_fdroid_overlay
assert_fdroid_source
