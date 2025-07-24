"use strict";
var __makeTemplateObject = (this && this.__makeTemplateObject) || function (cooked, raw) {
    if (Object.defineProperty) { Object.defineProperty(cooked, "raw", { value: raw }); } else { cooked.raw = raw; }
    return cooked;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddPasskeyForm = void 0;
var CalendarToday_1 = require("@mui/icons-material/CalendarToday");
var ChevronRight_1 = require("@mui/icons-material/ChevronRight");
var Delete_1 = require("@mui/icons-material/Delete");
var Edit_1 = require("@mui/icons-material/Edit");
var Key_1 = require("@mui/icons-material/Key");
var material_1 = require("@mui/material");
var EnteLogo_1 = require("ente-base/components/EnteLogo");
var LoadingButton_1 = require("ente-base/components/mui/LoadingButton");
var SidebarDrawer_1 = require("ente-base/components/mui/SidebarDrawer");
var Navbar_1 = require("ente-base/components/Navbar");
var RowButton_1 = require("ente-base/components/RowButton");
var SingleInputDialog_1 = require("ente-base/components/SingleInputDialog");
var dialog_1 = require("ente-base/components/utils/dialog");
var modal_1 = require("ente-base/components/utils/modal");
var context_1 = require("ente-base/context");
var i18n_date_1 = require("ente-base/i18n-date");
var log_1 = require("ente-base/log");
var formik_1 = require("formik");
var i18next_1 = require("i18next");
var react_1 = require("react");
var passkey_1 = require("services/passkey");
var Page = function () {
    var showMiniDialog = (0, context_1.useBaseContext)().showMiniDialog;
    var _a = (0, react_1.useState)(), token = _a[0], setToken = _a[1];
    var _b = (0, react_1.useState)([]), passkeys = _b[0], setPasskeys = _b[1];
    var _c = (0, react_1.useState)(false), showPasskeyDrawer = _c[0], setShowPasskeyDrawer = _c[1];
    var _d = (0, react_1.useState)(), selectedPasskey = _d[0], setSelectedPasskey = _d[1];
    var showPasskeyFetchFailedErrorDialog = (0, react_1.useCallback)(function () {
        showMiniDialog((0, dialog_1.errorDialogAttributes)((0, i18next_1.t)("passkey_fetch_failed")));
    }, [showMiniDialog]);
    (0, react_1.useEffect)(function () {
        var urlParams = new URLSearchParams(window.location.search);
        var token = urlParams.get("token");
        if (token) {
            setToken(token);
        }
        else {
            log_1.default.error("Missing accounts token");
            showPasskeyFetchFailedErrorDialog();
        }
    }, [showPasskeyFetchFailedErrorDialog]);
    var refreshPasskeys = (0, react_1.useCallback)(function () { return __awaiter(void 0, void 0, void 0, function () {
        var _a, e_1;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    _b.trys.push([0, 2, , 3]);
                    _a = setPasskeys;
                    return [4 /*yield*/, (0, passkey_1.getPasskeys)(token)];
                case 1:
                    _a.apply(void 0, [_b.sent()]);
                    return [3 /*break*/, 3];
                case 2:
                    e_1 = _b.sent();
                    log_1.default.error("Failed to fetch passkeys", e_1);
                    showPasskeyFetchFailedErrorDialog();
                    return [3 /*break*/, 3];
                case 3: return [2 /*return*/];
            }
        });
    }); }, [token, showPasskeyFetchFailedErrorDialog]);
    (0, react_1.useEffect)(function () {
        if (token) {
            void refreshPasskeys();
        }
    }, [token, refreshPasskeys]);
    var handleSelectPasskey = function (passkey) {
        setSelectedPasskey(passkey);
        setShowPasskeyDrawer(true);
    };
    var handleDrawerClose = function () {
        setShowPasskeyDrawer(false);
        // Don't clear the selected passkey, let the stale value be so that the
        // drawer closing animation is nicer.
        //
        // The value will get overwritten the next time we open the drawer for a
        // different passkey, so this will not have a functional impact.
    };
    var handleUpdateOrDeletePasskey = function () {
        setShowPasskeyDrawer(false);
        setSelectedPasskey(undefined);
        void refreshPasskeys();
    };
    return (<material_1.Stack sx={{ minHeight: "100svh" }}>
            <Navbar_1.NavbarBase>
                <EnteLogo_1.EnteLogo />
            </Navbar_1.NavbarBase>
            <material_1.Stack sx={{ alignSelf: "center", m: 3, maxWidth: "375px", gap: 3 }}>
                <material_1.Typography>{(0, i18next_1.t)("passkeys_description")}</material_1.Typography>
                <material_1.Paper sx={{ p: 2, pb: "29px" }}>
                    <exports.AddPasskeyForm token={token} onRefreshPasskeys={refreshPasskeys}/>
                </material_1.Paper>
                <PasskeysList passkeys={passkeys} onSelectPasskey={handleSelectPasskey}/>
            </material_1.Stack>

            <ManagePasskeyDrawer open={showPasskeyDrawer} onClose={handleDrawerClose} passkey={selectedPasskey} token={token} onUpdateOrDeletePasskey={handleUpdateOrDeletePasskey}/>
        </material_1.Stack>);
};
exports.default = Page;
var AddPasskeyForm = function (_a) {
    var _b;
    var token = _a.token, onRefreshPasskeys = _a.onRefreshPasskeys;
    var formik = (0, formik_1.useFormik)({
        initialValues: { value: "" },
        onSubmit: function (values_1, _a) { return __awaiter(void 0, [values_1, _a], void 0, function (values, _b) {
            var value, setValueFieldError, e_2;
            var setFieldError = _b.setFieldError, resetForm = _b.resetForm;
            return __generator(this, function (_c) {
                switch (_c.label) {
                    case 0:
                        value = values.value;
                        setValueFieldError = function (message) {
                            return setFieldError("value", message);
                        };
                        if (!value) {
                            setValueFieldError((0, i18next_1.t)("required"));
                            return [2 /*return*/];
                        }
                        _c.label = 1;
                    case 1:
                        _c.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, (0, passkey_1.registerPasskey)(token, value)];
                    case 2:
                        _c.sent();
                        return [3 /*break*/, 4];
                    case 3:
                        e_2 = _c.sent();
                        log_1.default.error("Failed to register a new passkey", e_2);
                        // If the user cancels the operation, then an error with name
                        // "NotAllowedError" is thrown.
                        //
                        // Ignore these, but in other cases add an error indicator to the
                        // add passkey text field. The browser is expected to already have
                        // shown an error dialog to the user.
                        if (!(e_2 instanceof Error && e_2.name == "NotAllowedError")) {
                            setValueFieldError((0, i18next_1.t)("passkey_add_failed"));
                        }
                        return [2 /*return*/];
                    case 4: return [4 /*yield*/, onRefreshPasskeys()];
                    case 5:
                        _c.sent();
                        resetForm();
                        return [2 /*return*/];
                }
            });
        }); },
    });
    return (<form onSubmit={formik.handleSubmit}>
            <material_1.TextField name="value" value={formik.values.value} onChange={formik.handleChange} type="text" fullWidth margin="normal" disabled={formik.isSubmitting} error={!!formik.errors.value} 
    // See: [Note: Use space as default TextField helperText]
    helperText={(_b = formik.errors.value) !== null && _b !== void 0 ? _b : " "} label={(0, i18next_1.t)("enter_passkey_name")}/>
            <LoadingButton_1.LoadingButton fullWidth color="accent" type="submit" loading={formik.isSubmitting}>
                {(0, i18next_1.t)("add_passkey")}
            </LoadingButton_1.LoadingButton>
        </form>);
};
exports.AddPasskeyForm = AddPasskeyForm;
var PasskeysList = function (_a) {
    var passkeys = _a.passkeys, onSelectPasskey = _a.onSelectPasskey;
    return (<RowButton_1.RowButtonGroup>
            {passkeys.map(function (passkey, i) { return (<react_1.default.Fragment key={passkey.id}>
                    <PasskeyListItem passkey={passkey} onClick={onSelectPasskey}/>
                    {i < passkeys.length - 1 && <RowButton_1.RowButtonDivider />}
                </react_1.default.Fragment>); })}
        </RowButton_1.RowButtonGroup>);
};
var PasskeyListItem = function (_a) {
    var passkey = _a.passkey, onClick = _a.onClick;
    return (<RowButton_1.RowButton startIcon={<Key_1.default />} endIcon={<ChevronRight_1.default />} label={<PasskeyLabel>
                <material_1.Typography sx={{ fontWeight: "medium" }}>
                    {passkey.friendlyName}
                </material_1.Typography>
            </PasskeyLabel>} onClick={function () { return onClick(passkey); }}/>);
};
var PasskeyLabel = (0, material_1.styled)("div")(templateObject_1 || (templateObject_1 = __makeTemplateObject(["\n    /* If the name of the passkey does not fit in one line, break the text into\n       multiple lines as necessary */\n    white-space: normal;\n"], ["\n    /* If the name of the passkey does not fit in one line, break the text into\n       multiple lines as necessary */\n    white-space: normal;\n"])));
var ManagePasskeyDrawer = function (_a) {
    var open = _a.open, onClose = _a.onClose, token = _a.token, passkey = _a.passkey, onUpdateOrDeletePasskey = _a.onUpdateOrDeletePasskey;
    var showMiniDialog = (0, context_1.useBaseContext)().showMiniDialog;
    var _b = (0, modal_1.useModalVisibility)(), showRenameDialog = _b.show, renameDialogVisibilityProps = _b.props;
    var handleRenamePasskeySubmit = (0, react_1.useCallback)(function (inputValue) { return __awaiter(void 0, void 0, void 0, function () {
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, (0, passkey_1.renamePasskey)(token, passkey.id, inputValue)];
                case 1:
                    _a.sent();
                    onUpdateOrDeletePasskey();
                    return [2 /*return*/];
            }
        });
    }); }, [token, passkey, onUpdateOrDeletePasskey]);
    var showDeleteConfirmationDialog = (0, react_1.useCallback)(function () {
        return showMiniDialog({
            title: (0, i18next_1.t)("delete_passkey"),
            message: (0, i18next_1.t)("delete_passkey_confirmation"),
            continue: {
                text: (0, i18next_1.t)("delete"),
                color: "critical",
                action: function () { return __awaiter(void 0, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0: return [4 /*yield*/, (0, passkey_1.deletePasskey)(token, passkey.id)];
                            case 1:
                                _a.sent();
                                onUpdateOrDeletePasskey();
                                return [2 /*return*/];
                        }
                    });
                }); },
            },
        });
    }, [showMiniDialog, token, passkey, onUpdateOrDeletePasskey]);
    return (<>
            <SidebarDrawer_1.SidebarDrawer anchor="right" {...{ open: open, onClose: onClose }}>
                {token && passkey && (<material_1.Stack sx={{ gap: "4px", py: "12px" }}>
                        <SidebarDrawer_1.SidebarDrawerTitlebar onClose={onClose} title={(0, i18next_1.t)("manage_passkey")} onRootClose={onClose}/>
                        <CreatedAtEntry>
                            {(0, i18n_date_1.formattedDateTime)(passkey.createdAt)}
                        </CreatedAtEntry>
                        <RowButton_1.RowButtonGroup sx={{ m: 1 }}>
                            <RowButton_1.RowButton startIcon={<Edit_1.default />} label={(0, i18next_1.t)("rename_passkey")} onClick={showRenameDialog}/>
                            <RowButton_1.RowButtonDivider />
                            <RowButton_1.RowButton color="critical" startIcon={<Delete_1.default />} label={(0, i18next_1.t)("delete_passkey")} onClick={showDeleteConfirmationDialog}/>
                        </RowButton_1.RowButtonGroup>
                    </material_1.Stack>)}
            </SidebarDrawer_1.SidebarDrawer>
            {token && passkey && (<SingleInputDialog_1.SingleInputDialog {...renameDialogVisibilityProps} title={(0, i18next_1.t)("rename_passkey")} label={(0, i18next_1.t)("name")} placeholder={(0, i18next_1.t)("enter_passkey_name")} initialValue={passkey.friendlyName} submitButtonTitle={(0, i18next_1.t)("rename")} onSubmit={handleRenamePasskeySubmit}/>)}
        </>);
};
var CreatedAtEntry = function (_a) {
    var children = _a.children;
    return (<material_1.Stack direction="row" sx={{ alignItems: "center", gap: 0.5, pb: 1 }}>
        <CalendarToday_1.default color="secondary" sx={{ m: "16px" }}/>
        <material_1.Box sx={{ py: 0.5 }}>
            <material_1.Typography>{(0, i18next_1.t)("created_at")}</material_1.Typography>
            <material_1.Typography variant="small" sx={{ color: "text.muted" }}>
                {children}
            </material_1.Typography>
        </material_1.Box>
    </material_1.Stack>);
};
var templateObject_1;
