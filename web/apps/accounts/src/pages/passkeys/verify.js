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
var Info_1 = require("@mui/icons-material/Info");
var Key_1 = require("@mui/icons-material/Key");
var material_1 = require("@mui/material");
var containers_1 = require("ente-base/components/containers");
var ActivityIndicator_1 = require("ente-base/components/mui/ActivityIndicator");
var FocusVisibleButton_1 = require("ente-base/components/mui/FocusVisibleButton");
var log_1 = require("ente-base/log");
var transform_1 = require("ente-utils/transform");
var i18next_1 = require("i18next");
var react_1 = require("react");
var passkey_1 = require("services/passkey");
var Page = function () {
    var _a = (0, react_1.useState)("loading"), status = _a[0], setStatus = _a[1];
    var _b = (0, react_1.useState)(), continuation = _b[0], setContinuation = _b[1];
    // Safari throws  sometimes
    // (no reason, just to show their incompetence). The retry doesn't seem to
    // help mostly, but cargo cult anyway.
    // The URL we're redirecting to on success.
    //
    // This will only be set when status is "redirecting*".
    var _c = (0, react_1.useState)(), successRedirectURL = _c[0], setSuccessRedirectURL = _c[1];
    /** Phase 1 of {@link authenticate}. */
    var authenticateBegin = (0, react_1.useCallback)(function () { return __awaiter(void 0, void 0, void 0, function () {
        var searchParams, redirect, redirectURL, clientPackage, passkeySessionID, beginResponse, e_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    if (!(0, passkey_1.isWebAuthnSupported)()) {
                        setStatus("webAuthnNotSupported");
                        return [2 /*return*/];
                    }
                    searchParams = new URLSearchParams(window.location.search);
                    redirect = (0, transform_1.nullToUndefined)(searchParams.get("redirect"));
                    redirectURL = redirect ? new URL(redirect) : undefined;
                    // Ensure that redirectURL is whitelisted, otherwise show an invalid
                    // "login" URL error to the user.
                    if (!redirectURL || !(0, passkey_1.isWhitelistedRedirect)(redirectURL)) {
                        log_1.default.error("Redirect '".concat(redirect, "' is not whitelisted"));
                        setStatus("unknownRedirect");
                        return [2 /*return*/];
                    }
                    clientPackage = (0, transform_1.nullToUndefined)(searchParams.get("clientPackage"));
                    if (!clientPackage) {
                        setStatus("unrecoverableFailure");
                        return [2 /*return*/];
                    }
                    setStatus("loading");
                    passkeySessionID = (0, transform_1.nullToUndefined)(searchParams.get("passkeySessionID"));
                    if (!passkeySessionID) {
                        setStatus("unrecoverableFailure");
                        return [2 /*return*/];
                    }
                    _a.label = 1;
                case 1:
                    _a.trys.push([1, 3, , 4]);
                    return [4 /*yield*/, (0, passkey_1.beginPasskeyAuthentication)(passkeySessionID)];
                case 2:
                    beginResponse = _a.sent();
                    return [3 /*break*/, 4];
                case 3:
                    e_1 = _a.sent();
                    log_1.default.error("Failed to begin passkey authentication", e_1);
                    setStatus(e_1 instanceof Error &&
                        e_1.message == passkey_1.passkeySessionAlreadyClaimedErrorMessage
                        ? "sessionAlreadyClaimed"
                        : "failed");
                    return [2 /*return*/];
                case 4: return [2 /*return*/, { redirectURL: redirectURL, passkeySessionID: passkeySessionID, clientPackage: clientPackage, beginResponse: beginResponse }];
            }
        });
    }); }, []);
    /**
     * Phase 2 of {@link authenticate}, separated by a potential user
     * interaction.
     */
    var authenticateContinue = (0, react_1.useCallback)(function (cont) { return __awaiter(void 0, void 0, void 0, function () {
        var redirectURL, passkeySessionID, clientPackage, beginResponse, ceremonySessionID, options, credential, e_2, authorizationResponse, e_3, _a;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    redirectURL = cont.redirectURL, passkeySessionID = cont.passkeySessionID, clientPackage = cont.clientPackage, beginResponse = cont.beginResponse;
                    ceremonySessionID = beginResponse.ceremonySessionID, options = beginResponse.options;
                    setStatus("waitingForUser");
                    _b.label = 1;
                case 1:
                    _b.trys.push([1, 3, , 4]);
                    return [4 /*yield*/, (0, passkey_1.signChallenge)(options.publicKey)];
                case 2:
                    credential = _b.sent();
                    if (!credential) {
                        setStatus("failedDuringSignChallenge");
                        return [2 /*return*/];
                    }
                    return [3 /*break*/, 4];
                case 3:
                    e_2 = _b.sent();
                    log_1.default.error("Failed to get credentials", e_2);
                    if (e_2 instanceof Error &&
                        e_2.name == "NotAllowedError" &&
                        e_2.message == "The document is not focused.") {
                        setStatus("needUserFocus");
                    }
                    else {
                        setStatus("failedDuringSignChallenge");
                    }
                    return [2 /*return*/];
                case 4:
                    setStatus("loading");
                    _b.label = 5;
                case 5:
                    _b.trys.push([5, 7, , 8]);
                    return [4 /*yield*/, (0, passkey_1.finishPasskeyAuthentication)({
                            passkeySessionID: passkeySessionID,
                            ceremonySessionID: ceremonySessionID,
                            clientPackage: clientPackage,
                            credential: credential,
                        })];
                case 6:
                    authorizationResponse = _b.sent();
                    return [3 /*break*/, 8];
                case 7:
                    e_3 = _b.sent();
                    log_1.default.error("Failed to finish passkey authentication", e_3);
                    setStatus("failed");
                    return [2 /*return*/];
                case 8:
                    setStatus(isHTTP(redirectURL) ? "redirectingWeb" : "redirectingApp");
                    _a = setSuccessRedirectURL;
                    return [4 /*yield*/, (0, passkey_1.passkeyAuthenticationSuccessRedirectURL)(redirectURL, passkeySessionID, authorizationResponse)];
                case 9:
                    _a.apply(void 0, [_b.sent()]);
                    return [2 /*return*/];
            }
        });
    }); }, []);
    /** (re)start the authentication flow */
    var authenticate = (0, react_1.useCallback)(function () { return __awaiter(void 0, void 0, void 0, function () {
        var cont;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, authenticateBegin()];
                case 1:
                    cont = _a.sent();
                    if (!cont) return [3 /*break*/, 3];
                    setContinuation(cont);
                    return [4 /*yield*/, authenticateContinue(cont)];
                case 2:
                    _a.sent();
                    _a.label = 3;
                case 3: return [2 /*return*/];
            }
        });
    }); }, [authenticateBegin, authenticateContinue]);
    (0, react_1.useEffect)(function () {
        void authenticate();
    }, [authenticate]);
    (0, react_1.useEffect)(function () {
        if (successRedirectURL)
            redirectToURL(successRedirectURL);
    }, [successRedirectURL]);
    var handleVerify = function () { return void authenticateContinue(continuation); };
    var handleRetry = function () { return void authenticate(); };
    var handleRecover = (function () {
        var searchParams = new URLSearchParams(window.location.search);
        var recover = (0, transform_1.nullToUndefined)(searchParams.get("recover"));
        if (!recover) {
            // [Note: Conditional passkey recover option on accounts]
            //
            // Only show the recover option if the calling app provided us with
            // the "recover" query parameter. For example, the mobile app does
            // not pass it since it already shows a recovery option within the
            // waiting screen that it shows.
            return undefined;
        }
        return function () { return (0, passkey_1.redirectToPasskeyRecoverPage)(new URL(recover)); };
    })();
    var handleRedirectAgain = function () { return redirectToURL(successRedirectURL); };
    var components = {
        loading: <ActivityIndicator_1.ActivityIndicator />,
        unknownRedirect: <UnknownRedirect />,
        webAuthnNotSupported: <WebAuthnNotSupported />,
        sessionAlreadyClaimed: <SessionAlreadyClaimed />,
        unrecoverableFailure: <UnrecoverableFailure />,
        failedDuringSignChallenge: (<RetriableFailed duringSignChallenge onRetry={handleRetry} onRecover={handleRecover}/>),
        failed: (<RetriableFailed onRetry={handleRetry} onRecover={handleRecover}/>),
        needUserFocus: <Verify onVerify={handleVerify}/>,
        waitingForUser: <WaitingForUser />,
        redirectingWeb: <RedirectingWeb />,
        redirectingApp: <RedirectingApp onRetry={handleRedirectAgain}/>,
    };
    return <containers_1.Stack100vhCenter>{components[status]}</containers_1.Stack100vhCenter>;
};
exports.default = Page;
// Not 100% accurate, but good enough for our purposes.
var isHTTP = function (url) { return url.protocol.startsWith("http"); };
var redirectToURL = function (url) {
    log_1.default.info("Redirecting to ".concat(url.href));
    window.location.href = url.href;
};
var UnknownRedirect = function () { return (<Failed message={(0, i18next_1.t)("passkey_login_invalid_url")}/>); };
var WebAuthnNotSupported = function () { return (<Failed message={(0, i18next_1.t)("passkeys_not_supported")}/>); };
var SessionAlreadyClaimed = function () { return (<ContentPaper>
        <SessionAlreadyClaimed_>
            <Info_1.default color="secondary"/>
            <material_1.Typography>
                {(0, i18next_1.t)("passkey_login_already_claimed_session")}
            </material_1.Typography>
        </SessionAlreadyClaimed_>
    </ContentPaper>); };
var SessionAlreadyClaimed_ = (0, material_1.styled)("div")(templateObject_1 || (templateObject_1 = __makeTemplateObject(["\n    display: flex;\n    flex-direction: column;\n    align-items: center;\n    gap: 2rem;\n"], ["\n    display: flex;\n    flex-direction: column;\n    align-items: center;\n    gap: 2rem;\n"])));
var UnrecoverableFailure = function () { return (<Failed message={(0, i18next_1.t)("passkey_login_generic_error")}/>); };
var Failed = function (_a) {
    var message = _a.message;
    return (<ContentPaper>
        <Info_1.default color="secondary"/>
        <material_1.Typography variant="h6">{(0, i18next_1.t)("passkey_login_failed")}</material_1.Typography>
        <material_1.Typography sx={{ color: "text.muted" }}>{message}</material_1.Typography>
    </ContentPaper>);
};
var ContentPaper = (0, material_1.styled)(material_1.Paper)(templateObject_2 || (templateObject_2 = __makeTemplateObject(["\n    width: 100%;\n    max-width: 24rem;\n    padding: 1rem;\n    /* Slight asymmetry, look visually better since the bottom half of the paper\n       is usually muted text that carries less visual weight. */\n    padding-block-end: 1.15rem;\n\n    display: flex;\n    flex-direction: column;\n    gap: 1rem;\n"], ["\n    width: 100%;\n    max-width: 24rem;\n    padding: 1rem;\n    /* Slight asymmetry, look visually better since the bottom half of the paper\n       is usually muted text that carries less visual weight. */\n    padding-block-end: 1.15rem;\n\n    display: flex;\n    flex-direction: column;\n    gap: 1rem;\n"])));
/**
 * Gain focus for the current page by requesting the user to explicitly click a
 * button. For more details, see the documentation for `Continuation`.
 */
var Verify = function (_a) {
    var onVerify = _a.onVerify;
    return (<ContentPaper>
        <Key_1.default color="secondary" fontSize="large"/>
        <material_1.Typography variant="h3">{(0, i18next_1.t)("passkey")}</material_1.Typography>
        <material_1.Typography sx={{ color: "text.muted" }}>
            {(0, i18next_1.t)("passkey_verify_description")}
        </material_1.Typography>
        <ButtonStack>
            <FocusVisibleButton_1.FocusVisibleButton onClick={onVerify} fullWidth color="accent">
                {(0, i18next_1.t)("verify")}
            </FocusVisibleButton_1.FocusVisibleButton>
        </ButtonStack>
    </ContentPaper>);
};
var RetriableFailed = function (_a) {
    var duringSignChallenge = _a.duringSignChallenge, onRetry = _a.onRetry, onRecover = _a.onRecover;
    return (<ContentPaper>
        <Info_1.default color="secondary" fontSize="large"/>
        <material_1.Typography variant="h5">{(0, i18next_1.t)("passkey_login_failed")}</material_1.Typography>
        <material_1.Typography sx={{ color: "text.muted" }}>
            {duringSignChallenge
            ? (0, i18next_1.t)("passkey_login_credential_hint")
            : (0, i18next_1.t)("passkey_login_generic_error")}
        </material_1.Typography>
        <ButtonStack>
            <FocusVisibleButton_1.FocusVisibleButton onClick={onRetry} fullWidth color="secondary">
                {(0, i18next_1.t)("try_again")}
            </FocusVisibleButton_1.FocusVisibleButton>
            {onRecover && (<FocusVisibleButton_1.FocusVisibleButton onClick={onRecover} fullWidth variant="text">
                    {(0, i18next_1.t)("recover_two_factor")}
                </FocusVisibleButton_1.FocusVisibleButton>)}
        </ButtonStack>
    </ContentPaper>);
};
var ButtonStack = (0, material_1.styled)("div")(templateObject_3 || (templateObject_3 = __makeTemplateObject(["\n    display: flex;\n    flex-direction: column;\n    margin-block-start: 1rem;\n    gap: 1rem;\n"], ["\n    display: flex;\n    flex-direction: column;\n    margin-block-start: 1rem;\n    gap: 1rem;\n"])));
var WaitingForUser = function () { return (<ContentPaper>
        <material_1.Typography variant="h3" sx={{ mt: 1 }}>
            {(0, i18next_1.t)("passkey_login")}
        </material_1.Typography>
        <material_1.Typography sx={{ color: "text.muted" }}>
            {(0, i18next_1.t)("passkey_login_instructions")}
        </material_1.Typography>
        <WaitingImgContainer>
            <img alt="" height={150} width={150} src="/images/ente-circular.png"/>
        </WaitingImgContainer>
    </ContentPaper>); };
var WaitingImgContainer = (0, material_1.styled)("div")(templateObject_4 || (templateObject_4 = __makeTemplateObject(["\n    display: flex;\n    justify-content: center;\n    margin-block-start: 1rem;\n"], ["\n    display: flex;\n    justify-content: center;\n    margin-block-start: 1rem;\n"])));
var RedirectingWeb = function () { return (<ContentPaper>
        <Info_1.default color="accent" fontSize="large"/>
        <material_1.Typography variant="h5">{(0, i18next_1.t)("passkey_verified")}</material_1.Typography>
        <material_1.Typography sx={{ color: "text.muted" }}>
            {(0, i18next_1.t)("redirecting_back_to_app")}
        </material_1.Typography>
    </ContentPaper>); };
var RedirectingApp = function (_a) {
    var onRetry = _a.onRetry;
    return (<ContentPaper>
        <Info_1.default color="accent" fontSize="large"/>
        <material_1.Typography variant="h5">{(0, i18next_1.t)("passkey_verified")}</material_1.Typography>
        <material_1.Typography sx={{ color: "text.muted" }}>
            {(0, i18next_1.t)("redirecting_back_to_app")}
        </material_1.Typography>
        <material_1.Typography sx={{ color: "text.muted" }}>
            {(0, i18next_1.t)("redirect_close_instructions")}
        </material_1.Typography>
        <ButtonStack>
            <FocusVisibleButton_1.FocusVisibleButton fullWidth color="secondary" onClick={onRetry}>
                {(0, i18next_1.t)("redirect_again")}
            </FocusVisibleButton_1.FocusVisibleButton>
        </ButtonStack>
    </ContentPaper>);
};
var templateObject_1, templateObject_2, templateObject_3, templateObject_4;
