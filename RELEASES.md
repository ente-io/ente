# Releases

1. Create a PR to bump up the version number in `pubspec.yaml`.

2. Once that is merged, tag main. This'll trigger the
   [workflow](.github/workflows/ci.yml) to (a) create a new GitHub release with
   the independently distributed APK, and (b) build and upload a release to
   Google Play.

3. Xcode Cloud has already been configured and will automatically build and
   release to TestFlight when step 1 was merged to main (you can see logs under
   the PR checks).
