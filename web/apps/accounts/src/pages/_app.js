"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("@fontsource-variable/inter");
var material_1 = require("@mui/material");
var styles_1 = require("@mui/material/styles");
var app_1 = require("ente-base/app");
var assert_1 = require("ente-base/assert");
var Head_1 = require("ente-base/components/Head");
var loaders_1 = require("ente-base/components/loaders");
var MiniDialog_1 = require("ente-base/components/MiniDialog");
var dialog_1 = require("ente-base/components/utils/dialog");
var hooks_app_1 = require("ente-base/components/utils/hooks-app");
var theme_1 = require("ente-base/components/utils/theme");
var context_1 = require("ente-base/context");
var i18next_1 = require("i18next");
var react_1 = require("react");
var App = function (_a) {
    var Component = _a.Component, pageProps = _a.pageProps;
    (0, hooks_app_1.useSetupLogs)({ disableDiskLogs: true });
    var isI18nReady = (0, hooks_app_1.useSetupI18n)();
    var _b = (0, dialog_1.useAttributedMiniDialog)(), showMiniDialog = _b.showMiniDialog, miniDialogProps = _b.miniDialogProps;
    // No code in the accounts app is currently expected to reach a code path
    // where they would need to "logout". Also, the accounts app doesn't store
    // any user specific persistent state that'd need to be cleared, so there
    // really isn't anything to do here even if we needed to.
    var logout = assert_1.assertionFailed;
    var baseContext = (0, react_1.useMemo)(function () { return (0, context_1.deriveBaseContext)({ logout: logout, showMiniDialog: showMiniDialog }); }, [logout, showMiniDialog]);
    var title = isI18nReady ? (0, i18next_1.t)("title_accounts") : app_1.staticAppTitle;
    return (<styles_1.ThemeProvider theme={theme_1.photosTheme}>
            <Head_1.CustomHead {...{ title: title }}/>
            <material_1.CssBaseline enableColorScheme/>
            <MiniDialog_1.AttributedMiniDialog {...miniDialogProps}/>

            <context_1.BaseContext value={baseContext}>
                {!isI18nReady && <loaders_1.LoadingIndicator />}
                {isI18nReady && <Component {...pageProps}/>}
            </context_1.BaseContext>
        </styles_1.ThemeProvider>);
};
exports.default = App;
