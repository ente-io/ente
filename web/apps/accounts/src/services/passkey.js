"use strict";
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
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.redirectToPasskeyRecoverPage = exports.passkeyAuthenticationSuccessRedirectURL = exports.finishPasskeyAuthentication = exports.signChallenge = exports.beginPasskeyAuthentication = exports.passkeySessionAlreadyClaimedErrorMessage = exports.shouldRestrictToWhitelistedRedirect = exports.isWhitelistedRedirect = exports.registerPasskey = exports.deletePasskey = exports.renamePasskey = exports.getPasskeys = exports.isWebAuthnSupported = void 0;
var user_1 = require("ente-accounts/services/user");
var app_1 = require("ente-base/app");
var crypto_1 = require("ente-base/crypto");
var env_1 = require("ente-base/env");
var http_1 = require("ente-base/http");
var origins_1 = require("ente-base/origins");
var transform_1 = require("ente-utils/transform");
var v4_1 = require("zod/v4");
/** Return true if the user's browser supports WebAuthn (Passkeys). */
var isWebAuthnSupported = function () { return !!navigator.credentials; };
exports.isWebAuthnSupported = isWebAuthnSupported;
/**
 * Variant of {@link authenticatedRequestHeaders} but for authenticated requests
 * made by the accounts app.
 *
 * @param token The accounts specific auth token to use for making API requests.
 */
var accountsAuthenticatedRequestHeaders = function (token) { return ({
    "X-Auth-Token": token,
    "X-Client-Package": app_1.clientPackageName,
}); };
var Passkey = v4_1.z.object({
    /** A unique ID for the passkey */
    id: v4_1.z.string(),
    /**
     * An arbitrary name associated by the user with the passkey (a.k.a
     * its "friendly name").
     */
    friendlyName: v4_1.z.string(),
    /**
     * Epoch microseconds when this passkey was created.
     */
    createdAt: v4_1.z.number(),
});
var GetPasskeysResponse = v4_1.z.object({
    passkeys: v4_1.z.array(Passkey).nullish().transform(transform_1.nullToUndefined),
});
/**
 * Fetch the existing passkeys for the user.
 *
 * @param token The accounts specific auth token to use for making API requests.
 *
 * @returns An array of {@link Passkey}s. The array will be empty if the user
 * has no passkeys.
 */
var getPasskeys = function (token) { return __awaiter(void 0, void 0, void 0, function () {
    var res, _a, passkeys, _b, _c;
    return __generator(this, function (_d) {
        switch (_d.label) {
            case 0:
                _a = fetch;
                return [4 /*yield*/, (0, origins_1.apiURL)("/passkeys")];
            case 1: return [4 /*yield*/, _a.apply(void 0, [_d.sent(), {
                        headers: accountsAuthenticatedRequestHeaders(token),
                    }])];
            case 2:
                res = _d.sent();
                (0, http_1.ensureOk)(res);
                _c = (_b = GetPasskeysResponse).parse;
                return [4 /*yield*/, res.json()];
            case 3:
                passkeys = _c.apply(_b, [_d.sent()]).passkeys;
                return [2 /*return*/, passkeys !== null && passkeys !== void 0 ? passkeys : []];
        }
    });
}); };
exports.getPasskeys = getPasskeys;
/**
 * Rename one of the user's existing passkey with the given {@link id}.
 *
 * @param token The accounts specific auth token to use for making API requests.
 *
 * @param id The `id` of the existing passkey to rename.
 *
 * @param name The new name (a.k.a. "friendly name").
 */
var renamePasskey = function (token, id, name) { return __awaiter(void 0, void 0, void 0, function () {
    var url, res;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0: return [4 /*yield*/, (0, origins_1.apiURL)("/passkeys/".concat(id), { friendlyName: name })];
            case 1:
                url = _a.sent();
                return [4 /*yield*/, fetch(url, {
                        method: "PATCH",
                        headers: accountsAuthenticatedRequestHeaders(token),
                    })];
            case 2:
                res = _a.sent();
                (0, http_1.ensureOk)(res);
                return [2 /*return*/];
        }
    });
}); };
exports.renamePasskey = renamePasskey;
/**
 * Delete one of the user's existing passkeys.
 *
 * @param token The accounts specific auth token to use for making API requests.
 *
 * @param id The `id` of the existing passkey to delete.
 */
var deletePasskey = function (token, id) { return __awaiter(void 0, void 0, void 0, function () {
    var res, _a;
    return __generator(this, function (_b) {
        switch (_b.label) {
            case 0:
                _a = fetch;
                return [4 /*yield*/, (0, origins_1.apiURL)("/passkeys/".concat(id))];
            case 1: return [4 /*yield*/, _a.apply(void 0, [_b.sent(), {
                        method: "DELETE",
                        headers: accountsAuthenticatedRequestHeaders(token),
                    }])];
            case 2:
                res = _b.sent();
                (0, http_1.ensureOk)(res);
                return [2 /*return*/];
        }
    });
}); };
exports.deletePasskey = deletePasskey;
/**
 * Add a new passkey as the second factor to the user's account.
 *
 * @param token The accounts specific auth token to use for making API requests.
 *
 * @param name An arbitrary name that the user wishes to label this passkey with
 * (a.k.a. "friendly name").
 */
var registerPasskey = function (token, name) { return __awaiter(void 0, void 0, void 0, function () {
    var _a, sessionID, options, credential;
    return __generator(this, function (_b) {
        switch (_b.label) {
            case 0: return [4 /*yield*/, beginPasskeyRegistration(token)];
            case 1:
                _a = _b.sent(), sessionID = _a.sessionID, options = _a.options;
                return [4 /*yield*/, navigator.credentials.create(options)];
            case 2:
                credential = (_b.sent());
                // Finish by letting the backend know about these credentials so that it can
                // save the public key for future authentication.
                return [4 /*yield*/, finishPasskeyRegistration({
                        token: token,
                        friendlyName: name,
                        sessionID: sessionID,
                        credential: credential,
                    })];
            case 3:
                // Finish by letting the backend know about these credentials so that it can
                // save the public key for future authentication.
                _b.sent();
                return [2 /*return*/];
        }
    });
}); };
exports.registerPasskey = registerPasskey;
var beginPasskeyRegistration = function (token) { return __awaiter(void 0, void 0, void 0, function () {
    var res, _a, _b, sessionID, options, _c, _d;
    return __generator(this, function (_e) {
        switch (_e.label) {
            case 0:
                _a = fetch;
                return [4 /*yield*/, (0, origins_1.apiURL)("/passkeys/registration/begin")];
            case 1: return [4 /*yield*/, _a.apply(void 0, [_e.sent(), {
                        method: "POST",
                        headers: accountsAuthenticatedRequestHeaders(token),
                    }])];
            case 2:
                res = _e.sent();
                (0, http_1.ensureOk)(res);
                return [4 /*yield*/, res.json()];
            case 3:
                _b = (_e.sent()), sessionID = _b.sessionID, options = _b.options;
                _c = options.publicKey;
                return [4 /*yield*/, serverB64ToBinary(options.publicKey.challenge)];
            case 4:
                _c.challenge = _e.sent();
                _d = options.publicKey.user;
                return [4 /*yield*/, serverB64ToBinary(options.publicKey.user.id)];
            case 5:
                _d.id = _e.sent();
                return [2 /*return*/, { sessionID: sessionID, options: options }];
        }
    });
}); };
/**
 * This is the function that does the dirty work for the binary conversion,
 * including the unfortunate typecasts.
 *
 * See: [Note: Converting binary data in WebAuthn API payloads]
 */
var serverB64ToBinary = function (b) { return __awaiter(void 0, void 0, void 0, function () {
    var b64String, bytes;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0:
                b64String = b;
                return [4 /*yield*/, (0, crypto_1.fromB64URLSafeNoPadding)(b64String)];
            case 1:
                bytes = _a.sent();
                // Cast again to satisfy the incomplete BufferSource type.
                return [2 /*return*/, bytes];
        }
    });
}); };
/**
 * This is the sibling of {@link serverB64ToBinary} that does the conversions in
 * the other direction.
 *
 * See: [Note: Converting binary data in WebAuthn API payloads]
 */
var binaryToServerB64 = function (b) { return __awaiter(void 0, void 0, void 0, function () {
    var bytes, b64String;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0:
                bytes = new Uint8Array(b);
                return [4 /*yield*/, (0, crypto_1.toB64URLSafeNoPadding)(bytes)];
            case 1:
                b64String = _a.sent();
                // Lie about the types to make the compiler happy.
                return [2 /*return*/, b64String];
        }
    });
}); };
var finishPasskeyRegistration = function (_a) { return __awaiter(void 0, [_a], void 0, function (_b) {
    var attestationResponse, attestationObject, clientDataJSON, transports, url, res;
    var token = _b.token, sessionID = _b.sessionID, friendlyName = _b.friendlyName, credential = _b.credential;
    return __generator(this, function (_c) {
        switch (_c.label) {
            case 0:
                attestationResponse = authenticatorAttestationResponse(credential);
                return [4 /*yield*/, binaryToServerB64(attestationResponse.attestationObject)];
            case 1:
                attestationObject = _c.sent();
                return [4 /*yield*/, binaryToServerB64(attestationResponse.clientDataJSON)];
            case 2:
                clientDataJSON = _c.sent();
                transports = attestationResponse.getTransports();
                return [4 /*yield*/, (0, origins_1.apiURL)("/passkeys/registration/finish", {
                        friendlyName: friendlyName,
                        sessionID: sessionID,
                    })];
            case 3:
                url = _c.sent();
                return [4 /*yield*/, fetch(url, {
                        method: "POST",
                        headers: accountsAuthenticatedRequestHeaders(token),
                        body: JSON.stringify({
                            id: credential.id,
                            // This is meant to be the ArrayBuffer version of the (base64
                            // encoded) `id`, but since we then would need to base64 encode it
                            // anyways for transmission, we can just reuse the same string.
                            rawId: credential.id,
                            type: credential.type,
                            response: { attestationObject: attestationObject, clientDataJSON: clientDataJSON, transports: transports },
                        }),
                    })];
            case 4:
                res = _c.sent();
                (0, http_1.ensureOk)(res);
                return [2 /*return*/];
        }
    });
}); };
/**
 * A function to hide the type casts necessary to extract an
 * {@link AuthenticatorAttestationResponse} from the {@link Credential} we
 * obtain during a new passkey registration.
 */
var authenticatorAttestationResponse = function (credential) {
    // We passed `options: { publicKey }` to `navigator.credentials.create`, and
    // so we will get back an `PublicKeyCredential`:
    // https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#creating_a_public_key_credential
    //
    // However, the return type of `create` is the base `Credential`, so we need
    // to cast.
    var pkCredential = credential;
    // Further, since this was a `create` and not a `get`, the
    // PublicKeyCredential.response will be an
    // `AuthenticatorAttestationResponse` (See same MDN reference).
    //
    // We need to cast again.
    var attestationResponse = pkCredential.response;
    return attestationResponse;
};
/**
 * Return `true` if the given {@link redirectURL} (obtained from the redirect
 * query parameter passed around during the passkey verification flow) is one of
 * the whitelisted URLs that we allow redirecting to on success.
 *
 * This check is likely not necessary but we've only kept it just to be on the
 * safer side. However, this gets in the way of people who are self hosting
 * Ente. So only do this check if we're running on our production servers (or
 * localhost).
 */
var isWhitelistedRedirect = function (redirectURL) {
    return (0, exports.shouldRestrictToWhitelistedRedirect)()
        ? _isWhitelistedRedirect(redirectURL)
        : true;
};
exports.isWhitelistedRedirect = isWhitelistedRedirect;
var shouldRestrictToWhitelistedRedirect = function () {
    // host includes port, hostname is sans port
    var hostname = new URL(window.location.origin).hostname;
    return (hostname.endsWith("localhost") ||
        hostname.endsWith(".ente.io") ||
        hostname.endsWith(".ente.sh"));
};
exports.shouldRestrictToWhitelistedRedirect = shouldRestrictToWhitelistedRedirect;
var _isWhitelistedRedirect = function (redirectURL) {
    return (env_1.isDevBuild && redirectURL.hostname.endsWith("localhost")) ||
        redirectURL.host.endsWith(".ente.io") ||
        redirectURL.host.endsWith(".ente.sh") ||
        redirectURL.protocol == "ente:" ||
        redirectURL.protocol == "enteauth:" ||
        redirectURL.protocol == "ente-cli:";
};
/**
 * The passkey session which we are trying to start an authentication ceremony
 * for has already finished elsewhere.
 */
exports.passkeySessionAlreadyClaimedErrorMessage = "Passkey session already claimed";
/**
 * Create a authentication ceremony session and return a challenge and a list of
 * public key credentials that can be used to attest that challenge.
 *
 * [Note: WebAuthn authentication flow]
 *
 * This is step 1 of passkey authentication flow as described in
 * https://developer.mozilla.org/en-US/docs/Web/API/Web_Authentication_API#authenticating_a_user
 *
 * @param passkeySessionID A session created by the requesting app that can be
 * used to initiate a passkey authentication ceremony on the accounts app.
 *
 * @throws In addition to arbitrary errors, it throws errors with the message
 * {@link passkeySessionAlreadyClaimedErrorMessage}.
 */
var beginPasskeyAuthentication = function (passkeySessionID) { return __awaiter(void 0, void 0, void 0, function () {
    var url, res, _a, ceremonySessionID, options, _b, _i, _c, credential, _d;
    var _e;
    return __generator(this, function (_f) {
        switch (_f.label) {
            case 0: return [4 /*yield*/, (0, origins_1.apiURL)("/users/two-factor/passkeys/begin")];
            case 1:
                url = _f.sent();
                return [4 /*yield*/, fetch(url, {
                        method: "POST",
                        headers: (0, http_1.publicRequestHeaders)(),
                        body: JSON.stringify({ sessionID: passkeySessionID }),
                    })];
            case 2:
                res = _f.sent();
                if (!res.ok) {
                    if (res.status == 409)
                        throw new Error(exports.passkeySessionAlreadyClaimedErrorMessage);
                    throw new http_1.HTTPError(res);
                }
                return [4 /*yield*/, res.json()];
            case 3:
                _a = (_f.sent()), ceremonySessionID = _a.ceremonySessionID, options = _a.options;
                _b = options.publicKey;
                return [4 /*yield*/, serverB64ToBinary(options.publicKey.challenge)];
            case 4:
                _b.challenge = _f.sent();
                _i = 0, _c = (_e = options.publicKey.allowCredentials) !== null && _e !== void 0 ? _e : [];
                _f.label = 5;
            case 5:
                if (!(_i < _c.length)) return [3 /*break*/, 8];
                credential = _c[_i];
                _d = credential;
                return [4 /*yield*/, serverB64ToBinary(credential.id)];
            case 6:
                _d.id = _f.sent();
                _f.label = 7;
            case 7:
                _i++;
                return [3 /*break*/, 5];
            case 8: return [2 /*return*/, { ceremonySessionID: ceremonySessionID, options: options }];
        }
    });
}); };
exports.beginPasskeyAuthentication = beginPasskeyAuthentication;
/**
 * Authenticate the user by asking them to use a passkey that the they had
 * previously created for the current domain to sign a challenge.
 *
 * This function implements steps 2 and 3 of the passkey authentication flow.
 * See [Note: WebAuthn authentication flow].
 *
 * @param publicKey A challenge and a list of public key credentials
 * ("passkeys") that can be used to attest that challenge.
 *
 * @returns A {@link PublicKeyCredential} that contains the signed
 * {@link AuthenticatorAssertionResponse}. Note that the type does not reflect
 * this specialization, and the result is a base {@link Credential}.
 */
var signChallenge = function (publicKey) { return __awaiter(void 0, void 0, void 0, function () {
    var _i, _a, cred, _b;
    var _c, _d;
    return __generator(this, function (_e) {
        switch (_e.label) {
            case 0:
                // Hint all transports to make security keys like Yubikey work across
                // varying registration/verification scenarios.
                //
                // During verification, we need to pass a `transport` property.
                //
                // > The `transports` property is hint of the methods that the client could
                // > use to communicate with the relevant authenticator of the public key
                // > credential to retrieve. Possible values are ["ble", "hybrid",
                // > "internal", "nfc", "usb"].
                // >
                // > MDN
                //
                // When we register a passkey, we save the transport alongwith the
                // credential. During authentication, we pass that transport back to the
                // browser. This is the approach recommended by the spec:
                //
                // > When registering a new credential, the Relying Party SHOULD store the
                // > value returned from getTransports(). When creating a
                // > PublicKeyCredentialDescriptor for that credential, the Relying Party
                // > SHOULD retrieve that stored value and set it as the value of the
                // > transports member.
                // >
                // > https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialdescriptor-transports
                //
                // However, following this recommendation break things currently (2024) in
                // various ways. For example, if a user registers a Yubikey NFC security key
                // on Firefox on their laptop, then Firefox returns ["usb"]. This is
                // incorrect, it should be ["usb", "nfc"] (which is what Chrome does, since
                // the hardware itself supports both USB and NFC transports).
                //
                // Later, if the user tries to verifying with their security key on their
                // iPhone Safari via NFC, the browser doesn't recognize it (which seems
                // incorrect too, the transport is meant to be a "hint" not a binding).
                //
                // > Note that these hints represent the WebAuthn Relying Party's best
                // > belief as to how an authenticator may be reached.
                // >
                // > https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialdescriptor-transports
                //
                // As a workaround, we override transports with known possible values.
                for (_i = 0, _a = (_c = publicKey.allowCredentials) !== null && _c !== void 0 ? _c : []; _i < _a.length; _i++) {
                    cred = _a[_i];
                    cred.transports = __spreadArray(__spreadArray([], ((_d = cred.transports) !== null && _d !== void 0 ? _d : []), true), [
                        "usb",
                        "nfc",
                        "ble",
                        "hybrid",
                        "internal",
                    ], false);
                }
                _b = transform_1.nullToUndefined;
                return [4 /*yield*/, navigator.credentials.get({ publicKey: publicKey })];
            case 1: return [2 /*return*/, _b.apply(void 0, [_e.sent()])];
        }
    });
}); };
exports.signChallenge = signChallenge;
/**
 * Finish the authentication by providing the signed assertion to the backend.
 *
 * This function implements steps 4 and 5 of the passkey authentication flow.
 * See [Note: WebAuthn authentication flow].
 *
 * @returns The result of successful authentication, a
 * {@link TwoFactorAuthorizationResponse}.
 */
var finishPasskeyAuthentication = function (_a) { return __awaiter(void 0, [_a], void 0, function (_b) {
    var response, authenticatorData, clientDataJSON, signature, userHandle, _c, params, url, res, _d, _e;
    var passkeySessionID = _b.passkeySessionID, ceremonySessionID = _b.ceremonySessionID, clientPackage = _b.clientPackage, credential = _b.credential;
    return __generator(this, function (_f) {
        switch (_f.label) {
            case 0:
                response = authenticatorAssertionResponse(credential);
                return [4 /*yield*/, binaryToServerB64(response.authenticatorData)];
            case 1:
                authenticatorData = _f.sent();
                return [4 /*yield*/, binaryToServerB64(response.clientDataJSON)];
            case 2:
                clientDataJSON = _f.sent();
                return [4 /*yield*/, binaryToServerB64(response.signature)];
            case 3:
                signature = _f.sent();
                if (!response.userHandle) return [3 /*break*/, 5];
                return [4 /*yield*/, binaryToServerB64(response.userHandle)];
            case 4:
                _c = _f.sent();
                return [3 /*break*/, 6];
            case 5:
                _c = null;
                _f.label = 6;
            case 6:
                userHandle = _c;
                params = new URLSearchParams({
                    sessionID: passkeySessionID,
                    ceremonySessionID: ceremonySessionID,
                    clientPackage: clientPackage,
                });
                return [4 /*yield*/, (0, origins_1.apiURL)("/users/two-factor/passkeys/finish")];
            case 7:
                url = _f.sent();
                return [4 /*yield*/, fetch("".concat(url, "?").concat(params.toString()), {
                        method: "POST",
                        headers: {
                            // Note: Unlike the other requests, this is the clientPackage of the
                            // _requesting_ app, not the accounts app.
                            "X-Client-Package": clientPackage,
                        },
                        body: JSON.stringify({
                            id: credential.id,
                            // This is meant to be the ArrayBuffer version of the (base64
                            // encoded) `id`, but since we then would need to base64 encode it
                            // anyways for transmission, we can just reuse the same string.
                            rawId: credential.id,
                            type: credential.type,
                            response: {
                                authenticatorData: authenticatorData,
                                clientDataJSON: clientDataJSON,
                                signature: signature,
                                userHandle: userHandle,
                            },
                        }),
                    })];
            case 8:
                res = _f.sent();
                (0, http_1.ensureOk)(res);
                _e = (_d = user_1.TwoFactorAuthorizationResponse).parse;
                return [4 /*yield*/, res.json()];
            case 9: return [2 /*return*/, _e.apply(_d, [_f.sent()])];
        }
    });
}); };
exports.finishPasskeyAuthentication = finishPasskeyAuthentication;
/**
 * A function to hide the type casts necessary to extract a
 * {@link AuthenticatorAssertionResponse} from the {@link Credential} we obtain
 * during a passkey attestation.
 */
var authenticatorAssertionResponse = function (credential) {
    // We passed `options: { publicKey }` to `navigator.credentials.get`, and so
    // we will get back an `PublicKeyCredential`:
    // https://developer.mozilla.org/en-US/docs/Web/API/CredentialsContainer/get#web_authentication_api
    //
    // However, the return type of `get` is the base `Credential`, so we need to
    // cast.
    var pkCredential = credential;
    // Further, since this was a `get` and not a `create`, the
    // PublicKeyCredential.response will be an `AuthenticatorAssertionResponse`
    // (See same MDN reference).
    //
    // We need to cast again.
    var assertionResponse = pkCredential.response;
    return assertionResponse;
};
/**
 * Create a redirection URL to get back to the calling app that initiated the
 * passkey authentication flow with the result of the authentication.
 *
 * @param redirectURL The base URL to redirect to. Provided by the calling app
 * that initiated the passkey authentication.
 *
 * @param passkeySessionID The passkeySessionID that was provided by the calling
 * app that initiated the passkey authentication. It is returned back in the
 * response so that the calling app has a way to ensure that this is indeed a
 * redirect for the session that they initiated and are waiting for.
 *
 * @param twoFactorAuthorizationResponse The result of
 * {@link finishPasskeyAuthentication} returned by the backend.
 */
var passkeyAuthenticationSuccessRedirectURL = function (redirectURL, passkeySessionID, twoFactorAuthorizationResponse) { return __awaiter(void 0, void 0, void 0, function () {
    var encodedResponse;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0: return [4 /*yield*/, (0, crypto_1.toB64URLSafeNoPadding)(new TextEncoder().encode(JSON.stringify(twoFactorAuthorizationResponse)))];
            case 1:
                encodedResponse = _a.sent();
                redirectURL.searchParams.set("passkeySessionID", passkeySessionID);
                redirectURL.searchParams.set("response", encodedResponse);
                return [2 /*return*/, redirectURL];
        }
    });
}); };
exports.passkeyAuthenticationSuccessRedirectURL = passkeyAuthenticationSuccessRedirectURL;
/**
 * Redirect back to the app that initiated the passkey authentication,
 * navigating the user to a place where they can reset their second factor using
 * their recovery key (e.g. if they have lost access to their passkey).
 *
 * The same considerations mentioned in [Note: Finish passkey flow in the
 * requesting app] apply to recovery too, which is why we need to redirect back
 * to the app on whose behalf we're authenticating.
 *
 * @param recoverURL The recovery URL provided as a query parameter by the app
 * that called us.
 */
var redirectToPasskeyRecoverPage = function (recoverURL) {
    window.location.href = recoverURL.href;
};
exports.redirectToPasskeyRecoverPage = redirectToPasskeyRecoverPage;
