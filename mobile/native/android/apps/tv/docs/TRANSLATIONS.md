# Translations (Crowdin)

This app is wired for Android string-resource localization and Crowdin sync.

## Source files
- `app/src/main/res/values/strings.xml`
- `app/src/main/res/values/arrays.xml`

All user-facing UI/setup text is stored in these resource files, so translators can work without touching Kotlin/XML layout code.

## Crowdin config
- `crowdin.yml` maps source files to Android locale folders:
  - `values/strings.xml` → `values-%android_code%/strings.xml`
  - `values/arrays.xml` → `values-%android_code%/arrays.xml`

## Typical workflow
1. Set env vars:
   - `CROWDIN_PROJECT_ID`
   - `CROWDIN_PERSONAL_TOKEN`
2. Upload source strings:
   - `crowdin upload sources`
3. Download translated files:
   - `crowdin download`

Downloaded locales will appear as `app/src/main/res/values-xx/` (or `values-xx-rYY/`) resource folders, ready for Android builds.
