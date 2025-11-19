## Staged code changes (detailed)

### Flow: selecting a sidebar search suggestion in `web/packages/new/photos/components/SearchBar.tsx`
1) The search option emitted by `SearchBar` contains a `suggestion` object that includes `type`. For `type === "sidebarAction"`, the handler in `web/apps/photos/src/pages/gallery.tsx` now:
   - Reads `suggestion.actionID` (a `SidebarActionID`) and stores it in local state `pendingSidebarAction`.
   - Immediately opens the sidebar (`showSidebar()`), so the action can run in the sidebar UI.
   - Exits search mode unless the caller opted out via `options?.shouldExitSearchMode`.
2) `Gallery.tsx` renders `Sidebar` with `pendingAction={pendingSidebarAction}` and an `onActionHandled` callback that clears the pending action once the sidebar confirms it processed it.

Data flow (search → gallery → sidebar):
```
SearchBar (selects suggestion.type === "sidebarAction")
    |
    v
Gallery handleSearchSelect
    - setPendingSidebarAction(actionID)
    - showSidebar()
    - exitSearchMode? (optional)
    |
    v
<Sidebar pendingAction=... onActionHandled=clear>
```

- Handler that captures the sidebar action and opens the drawer (`web/apps/photos/src/pages/gallery.tsx:783-817`):
```ts
const handleSelectSearchOption = (searchOption, options) => {
    if (searchOption) {
        const type = searchOption.suggestion.type;
        if (type == "sidebarAction") {
            setPendingSidebarAction(searchOption.suggestion.actionID);
            showSidebar();
            const shouldExitSearchMode = options?.shouldExitSearchMode ?? true;
            dispatch({ type: "exitSearch", shouldExitSearchMode });
        }
        // ...other cases omitted
    } else {
        dispatch({ type: "exitSearch", shouldExitSearchMode });
    }
};
```

### Mapping action IDs to real UI behavior
- `web/packages/new/photos/services/search/sidebar-search-registry.ts` now exports:
  - `SidebarActionContext`: bundles all callbacks the sidebar needs (close sidebar, open collection summaries including pseudo IDs for uncategorized/archive/hidden/trash, show Account/Preferences/Help drawers, show Export, logout, route to deduplicate, show Watch Folders, and setters to queue nested drawer actions).
  - `performSidebarAction(actionID, ctx)`: a single dispatcher that translates every `SidebarActionID` into concrete UI work using the supplied context:
    - Shortcuts: call `onShowCollectionSummary` with the correct pseudo ID (uncategorized/archive/hidden/trash), then close the sidebar.
    - Utility: open account/preferences/help drawers, trigger export, logout, watch folders, or navigate to /duplicates.
    - Account/Preferences/Help sub-actions: set the relevant pending action state (e.g., `account.recoveryKey`, `preferences.customDomains`, `help.viewLogs`), open the corresponding nested drawer, and return.
  - This consolidates action routing logic in one place so search-triggered sidebar actions reuse the same behavior as clicking buttons inside the sidebar.

Dispatcher snippet (`web/packages/new/photos/services/search/sidebar-search-registry.ts:251-331`):
```ts
export const performSidebarAction = async (actionID, ctx) => {
    switch (actionID) {
        case "shortcuts.uncategorized":
            return ctx.onShowCollectionSummary(ctx.pseudoIDs.uncategorized, false)
                .then(() => ctx.onClose());
        case "utility.export":
            ctx.onShowExport();
            ctx.onClose();
            return Promise.resolve();
        case "account.recoveryKey":
        case "account.deleteAccount":
            ctx.setPendingAccountAction(actionID);
            ctx.showAccount();
            return Promise.resolve();
        case "preferences.customDomains":
        case "preferences.mlSearch":
            ctx.setPendingPreferencesAction(actionID);
            ctx.showPreferences();
            return Promise.resolve();
        case "help.viewLogs":
        case "help.testUpload":
            ctx.setPendingHelpAction(actionID);
            ctx.showHelp();
            return Promise.resolve();
        // ...other switch cases cover archive/hidden/trash/deduplicate/logout/support/etc.
    }
};
```

### How `Sidebar` orchestrates the pending action
- `web/apps/photos/src/components/Sidebar.tsx` now accepts `pendingAction`/`onActionHandled` props and wires them to the registry helper:
  - On render/update, a `useEffect` detects `pendingAction` and calls `performSidebarAction(pendingAction, ctx)` where `ctx` supplies router helpers, modal openers, export/logout hooks, pseudo collection IDs, and setters for nested drawer pending actions. Once the promise settles, it invokes `onActionHandled` to clear the pending ID in the page.
  - The sidebar keeps internal pending states for nested drawers (`pendingAccountAction`, `pendingPreferencesAction`, `pendingHelpAction`). When `performSidebarAction` receives sub-action IDs, it sets these and opens the appropriate drawer.
- Each nested drawer executes its queued action as soon as it is visible:
  - `Account`: on open, switch on `pendingAction` to open Recovery Key / Two-factor / Delete Account modals, push change-password/change-email routes, or launch Passkeys; then call `onActionHandled`.
  - `Preferences`: on open, switch on `pendingAction` to open ML Search, Custom Domains, Map, or Advanced settings; then `onActionHandled`.
  - `Help`: on open, switch on `pendingAction` to open Help Center, Blog, Request Feature, Support email, View Logs (with confirmation), or test upload (dev only); then `onActionHandled`.

Data flow (Sidebar dispatch + nested drawers):
```
Sidebar (pendingAction present)
    |
    v
performSidebarAction(actionID, ctx)
    |-- if shortcut/utility: run action immediately (show collection, export, logout, etc.)
    |
    |-- if nested action:
          sets pendingAccountAction / pendingPreferencesAction / pendingHelpAction
          opens corresponding drawer
                 |
                 v
          Nested drawer useEffect(on open)
                 -> switch(pendingAction) -> run target task
                 -> onActionHandled() to clear local pending
    |
    v
Sidebar onActionHandled() -> Gallery clears pendingSidebarAction
```

Sidebar mounting the dispatcher (`web/apps/photos/src/components/Sidebar.tsx:287-333`):
```ts
const performSidebarAction = useCallback(
    async (actionID: SidebarActionID) =>
        performSidebarRegistryAction(actionID, {
            onClose,
            onShowCollectionSummary: showCollectionSummaryWithWorkarounds,
            showAccount,
            showPreferences,
            showHelp,
            onShowExport,
            onLogout: handleLogout,
            onRouteToDeduplicate: () => router.push("/duplicates"),
            onShowWatchFolder: handleOpenWatchFolder,
            pseudoIDs: { uncategorized, archive, hidden, trash },
            setPendingAccountAction: (a) => setPendingAccountAction(a as AccountAction | undefined),
            setPendingPreferencesAction: (a) => setPendingPreferencesAction(a as PreferencesAction | undefined),
            setPendingHelpAction: (a) => setPendingHelpAction(a as HelpAction | undefined),
        } as SidebarActionContext),
    [...deps],
);

useEffect(() => {
    if (!pendingAction) return;
    void performSidebarAction(pendingAction).finally(() =>
        onActionHandled?.(pendingAction),
    );
}, [pendingAction, performSidebarAction, onActionHandled]);
```

Nested drawer execution snippets:
- Account (`web/apps/photos/src/components/Sidebar.tsx:912-935`):
```ts
useEffect(() => {
    if (!open || !pendingAction) return;
    switch (pendingAction) {
        case "account.recoveryKey": showRecoveryKey(); break;
        case "account.twoFactor": showTwoFactor(); break;
        case "account.passkeys": void handlePasskeys(); break;
        case "account.changePassword": handleChangePassword(); break;
        case "account.changeEmail": handleChangeEmail(); break;
        case "account.deleteAccount": showDeleteAccount(); break;
    }
    onActionHandled?.();
}, [open, pendingAction, ...]);
```
- Preferences (`web/apps/photos/src/components/Sidebar.tsx:1038-1059`):
```ts
useEffect(() => {
    if (!open || !pendingAction) return;
    switch (pendingAction) {
        case "preferences.customDomains": showDomainSettings(); break;
        case "preferences.map": showMapSettings(); break;
        case "preferences.advanced": showAdvancedSettings(); break;
        case "preferences.mlSearch": showMLSettings(); break;
        // other preference IDs are no-ops; UI already on the page
    }
    onActionHandled?.();
}, [open, pendingAction, ...]);
```
- Help (`web/apps/photos/src/components/Sidebar.tsx:1600-1625`):
```ts
useEffect(() => {
    if (!open || !pendingAction) return;
    switch (pendingAction) {
        case "help.helpCenter": handleHelp(); break;
        case "help.blog": handleBlog(); break;
        case "help.requestFeature": handleRequestFeature(); break;
        case "help.support": handleSupport(); break;
        case "help.viewLogs": confirmViewLogs(); break;
        case "help.testUpload":
            if (isDevBuildAndUser()) { void testUpload(); }
            break;
    }
    onActionHandled?.();
}, [open, pendingAction, ...]);
```

### Net result
- Selecting a sidebar-oriented suggestion in `SearchBar` now drives a deterministic flow: capture action ID in `Gallery` ➜ open sidebar ➜ `Sidebar` delegates to `performSidebarAction` ➜ action either triggers immediately (e.g., Export, Logout, show pseudo collections) or queues a nested drawer operation that runs as soon as the drawer opens. All pending flags are cleared after execution so repeated actions behave cleanly.
