# Translations

We use Crowdin for translations, and the `intl` package to load these at
runtime.

Within our project we have the _source_ strings - these are the key value pairs
in the `lib/l10n/intl_en.arb` file.

Volunteers can add a new _translation_ in their language corresponding to each
such source key-value to our
[Crowdin project](https://crowdin.com/project/ente-photos-app).

When a new source string is added, we run a [GitHub workflow](../../.github/workflows/mobile-crowdin-push.yml)
that

-   Uploads sources to Crowdin - So any new key value pair we add in the source
    `intl_en.arb` becomes available to translators to translate.

Every monday, we run a [GitHub workflow](../../.github/workflows/mobile-crowdin-sync.yml)
that 

-   Downloads translations from Crowdin - So any new translations that
    translators have made on the Crowdin dashboard (for existing sources) will
    be added to the corresponding `intl_XX.arb`.

The workflow also uploads existing translations and also downloads new sources
from Crowdin, but these two should be no-ops.

## Adding a new string

-   Add a new entry in `lib/l10n/intl_en.arb` (the
    **source `intl_en.arb`**).
-   Use the new key in code with the `S` class
    (`import "package:photos/generated/l10n.dart"`).
-   During the next sync, the workflow will upload this source item to Crowdin's
    dashboard, allowing translators to translate it.

## Updating an existing string

-   Update the existing value for the key in the source `intl_en.arb`.
-   During the next sync, the workflow will clear out all the existing
    translations so that they can be translated afresh.

## Deleting an existing string

-   Remove the key value pair from the source `intl_en.arb`.
-   During the next sync, the workflow will delete that source item from all
    existing translations (both in the Crowdin project and also from the
    other `intl_XX.arb` files in the repository).
