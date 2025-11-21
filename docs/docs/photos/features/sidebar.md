# Photos sidebar

This page documents the items rendered by `web/apps/photos/src/components/Sidebar.tsx`, along with any conditions that control when they show up or how they behave.

## User details and subscription

- [X][x] **Subscription**: always availble, open up the plan selector.

## Shortcuts

- [x][x] **Uncategorized**: always available; uses `uncategorizedCollectionSummaryID` and shows its file count.
- [X][x] **Archive**: always available; uses `PseudoCollectionID.archiveItems` file count.
- [X][x] **Hidden**: always available; calls `onShowCollectionSummary` with the hidden flag (reauth can fire before showing); caption shows a lock icon.
- [X][x] **Trash**: always available; uses `PseudoCollectionID.trash` file count.

## Utilities

- [X][x] **Account**: opens the account drawer (see below).
- [ ][x] **Watch folders**: only shown on desktop builds (`isDesktop`).
- [X][x] **Deduplicate files**: always shown; navigates to `/duplicates`.
- [X][x] **Preferences**: opens the preferences drawer (see below).
- [X][x] **Help**: opens the help drawer (see below).
- [X][x] **Export data**: always shown; end icon indicates an in-progress export. On desktop it triggers `onShowExport`; on web it shows the "download app" dialog instead.

## Account drawer

- [X][x] **Recovery key**: always available; opens the recovery key flow.
- [X][x] **Two-factor**: always available; opens the 2FA settings.
- [X][x] **Passkeys**: always available; closes the sidebar then opens the accounts passkey management page.
- [X][x] **Change password / Change email**: always available; navigates to the respective routes.
- [X][x] **Delete account**: always available; uses `onAuthenticateUser` before proceeding.

## Preferences drawer

- [X][x] **Language**: always available; lists `supportedLocales` and triggers a full reload on change.
- [X][x] **Theme**: shown once a color scheme is available (skips during SSR); options are system, light, dark.
- [ ][x] **ML search**: shown only when `isMLSupported` is true; opens the ML settings drawer.
- [X][x] **Custom domains**: always available; opens domain settings (see below).
- [X][x] **Map**: always available; opens map settings (see below).
- [X][x] **Advanced**: always available; opens advanced settings (see below).
- [ ][x] **Streamable videos**: shown only when `isHLSGenerationSupported` is true; toggles HLS generation via `toggleHLSGeneration` using the status snapshot for the initial state.


## Advanced settings

- [X][x] **Faster upload**: always shown; toggles the Cloudflare upload proxy (`cfUploadProxyDisabled` inverted).
- [ ][x] **Open Ente on startup**: only shown when running in the Electron shell (`globalThis.electron` exists); toggles auto-launch and refreshes the current state from `electron.isAutoLaunchEnabled()`.

## Help drawer

- [X][x] **Ente help**: opens https://ente.io/help/photos/.
- [X][x] **Blog**: opens https://ente.io/blog/.
- [X][x] **Request feature**: opens GitHub Discussions for feature requests.
- [X][x] **Support**: opens an email to support@ente.io.
- [X][x] **View logs**: always shown; on Electron opens the log directory, otherwise downloads logs as a file.
- [ ] **Test upload**: only shown on dev builds for dev users (`isDevBuildAndUser()` returns true); runs the `testUpload` helper.

## Exit and app info

- [X][x] **Logout**: always shown; asks for confirmation before calling logout.


