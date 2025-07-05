import {
    deriveSubKeyBytes,
    generateDeriveKeySalt,
    toB64,
} from "ente-base/crypto";
import {
    authenticatedRequestHeaders,
    ensureOk,
    publicRequestHeaders,
} from "ente-base/http";
import { apiURL } from "ente-base/origins";
import { ensure } from "ente-utils/ensure";
import { SRP, SrpClient } from "fast-srp-hap";
import { v4 as uuidv4 } from "uuid";
import { z } from "zod/v4";
import { saveSRPAttributes } from "./accounts-db";
import {
    RemoteSRPVerificationResponse,
    type EmailOrSRPVerificationResponse,
} from "./user";

/**
 * The SRP attributes for a user.
 *
 * These are created by a client on signup, saved to remote. During logins, they
 * are fetched from remote. In both cases they are also persisted in local
 * storage (both network ops and local storage use the same schema).
 *
 * [Note: SRP]
 *
 * The SRP (Secure Remote Password) protocol is a modified Diffie-Hellman key
 * exchange that allows the remote to verify the user's possession of a
 * password, and the user to ensure that remote is not being impersonated,
 * without the password ever leaving the device.
 *
 * It is used as an (user selectable) alternative to email verification.
 *
 * For more about the what and why, see the announcement blog post
 * https://ente.io/blog/ente-adopts-secure-remote-passwords/
 *
 * Here we do not focus on the math (the above blog post links to reference
 * material, and there is also an RFC), but instead of the various bits of
 * information that get exchanged.
 *
 * Broadly, there are two scenarios: SRP setup, and SRP verification.
 *
 * [Note: SRP setup] -------------------
 *
 * During SRP setup, client generates
 *
 * 01. A SRP user ID (a new UUID-v4)
 * 02. A SRP password (deterministically derived from their regular KEK)
 * 03. A SRP salt (randomly generated)
 *
 * These 3 things are enough to create a SRP verifier and client. The SRP client
 * can just be thought of an ephemeral stateful mechanism to avoid passing all
 * the state accrued so far to each operation. Each time when creating a SRP
 * client, the app generates a new random secret and uses it during init.
 *
 * 04. Compute verifier = computeSRPVerifier({ userID, password, salt })
 * 05. Generates a new (ephemeral and random) clientSecret
 * 06. Create client = new SRPClient({ userID, password, salt, clientSecret })
 *
 * The client (app) then starts the setup ceremony with remote:
 *
 * 07. Use SRP client to conjure secret `a` and use that to compute a public A
 * 08. Send { userID, salt, verifier, A } to remote ("/users/srp/setup")
 *
 * Remote then:
 *
 * 09. Generates a new (ephemeral and random) serverSecret
 * 10. Saves { userID, serverSecret, A } into SRP sessions table
 * 11. Creates server = new SRPServer({ verifier, serverSecret })
 * 12. Uses SRP server to conjure secret `b` and use that to compute a public B
 * 13. Stashes { sessionID, userID, salt, verifier } into SRP setups table
 * 14. Returns { setupID, B } to client
 *
 * Client then
 *
 * 15. Tells its SRP client about B
 * 16. Computes SRP M1 (evidence message) using the SRP client
 * 17. Sends { setupID, M1 } to remote ("/users/srp/complete")
 *
 * Remote then
 *
 * 18. Uses setupID to read the stashed { sessionID, verifier }
 * 19. Uses sessionID to read { serverSecret, A }
 * 20. Recreates server = new SRPServer({ verifier, serverSecret })
 * 21. Sets server.A
 * 22. Verifies M1 using the SRP server, obtaining a SRP M2 (evidence message)
 * 23. Returns M2
 *
 * Client then
 *
 * 24. Verifies M2
 *
 * SRP setup is now complete.
 *
 * A similar flow is used when the user changes their password. On password
 * change, a new KEK is generated, thus the SRP password also changes, and so a
 * subset of the steps above are done to update both client and remote.
 *
 * [Note: SRP verification] -----------------------
 *
 * When the user is signing on a new device, the client
 *
 * 01. Fetches SRP attributes for a user to get { (SRP) userID, (SRP) salt }
 * 02. Rederives SRP password from their KEK
 * 03. Generates a new (ephemeral and random) clientSecret
 * 04. Creates client = new SRPClient({ userID, password, salt, clientSecret })
 * 05. Uses SRP client to conjure secret `a` and use that to compute a public A
 * 06. Sends { userID, A } to remote ("/users/srp/create-session")
 *
 * Remote
 *
 * 07. Retrieves { verifier } corresponding to the userID
 * 08. Generates a new (ephemeral and random) serverSecret
 * 09. Saves { userID, serverSecret, A } into SRP sessions table
 * 10. Creates server = new SRPServer({ verifier, serverSecret })
 * 11. Sets server.A
 * 12. Uses SRP server to conjure secret `b` and use that to compute a public B
 * 13. Returns { sessionID, B } to client
 *
 * Client then
 *
 * 14. Sets client.B
 * 15. Computes M1 (evidence message)
 * 16. Sends { userID, sessionID, M1 } to remote ("/users/srp/verify-session")
 *
 * Remote
 *
 * 17. Retrieves { verifier } corresponding to the userID
 * 17. Retrieves { serverSecret, A } using sessionID
 * 18. Recreates server = new SRPServer({ verifier, serverSecret })
 * 19. Sets server.A
 * 20. Verifies M1 using the SRP server, obtaining a SRP M2 (evidence message)
 * 21. Returns M2
 *
 * Client then
 *
 * 22. Verifies M2
 *
 * SRP verification is now complete.
 */
export interface SRPAttributes {
    /**
     * The SRP user ID for the (Ente) user.
     *
     * Each Ente user gets a new randomly generated UUID v4 assigned as their
     * SRP user ID during SRP setup.
     */
    srpUserID: string;
    /**
     * The SRP salt.
     *
     * This is a randomly generated salt created for each SRP user during SRP
     * setup. It is not meant to be secret.
     */
    srpSalt: string;
    /**
     * The mem limit used during the KEK derivation from the password.
     *
     * See also the discussion in {@link kekSalt}.
     */
    memLimit: number;
    /**
     * The ops limit used during the KEK derivation from the password.
     *
     * See also the discussion in {@link kekSalt}.
     */
    opsLimit: number;
    /**
     * The salt used during the KEK derivation from the password.
     *
     * Base64 encoded.
     *
     * This is the same value as the {@link kekSalt} in {@link KeyAttributes},
     * made available by remote also as part of SRP attributes for convenience.
     * See: [Note: KEK three tuple] for more details.
     */
    kekSalt: string;
    /**
     * If true, then the client should use email verification instead of SRP.
     */
    isEmailMFAEnabled: boolean;
}

/**
 * Zod schema for the {@link SRPAttributes} TypeScript type.
 *
 * We retain the SRP attributes response we get from remote verbatim when saving
 * it to local storage, so the same schema describes both the remote type and
 * the local storage type.
 */
export const RemoteSRPAttributes = z.object({
    srpUserID: z.string(),
    srpSalt: z.string(),
    memLimit: z.number(),
    opsLimit: z.number(),
    kekSalt: z.string(),
    isEmailMFAEnabled: z.boolean(),
});

/**
 * Fetch the {@link SRPAttributes} from remote for the Ente user with the
 * provided email.
 *
 * Returns `undefined` if either there is no Ente user with the given
 * {@link email}, or if there is a a user but they've not yet completed the SRP
 * setup ceremony.
 *
 * @param email The email of the user whose SRP attributes we're fetching.
 */
export const getSRPAttributes = async (
    email: string,
): Promise<SRPAttributes | undefined> => {
    const res = await fetch(await apiURL("/users/srp/attributes", { email }), {
        headers: publicRequestHeaders(),
    });
    if (res.status == 404) return undefined;
    ensureOk(res);
    return z.object({ attributes: RemoteSRPAttributes }).parse(await res.json())
        .attributes;
};

/**
 * A local-only structure holding information required for SRP setup.
 *
 * [Note: SRP setup attributes]
 *
 * In some cases, there might be a step between the client having access to the
 * KEK (which we need for generating the SRP attributes, in particular the SRP
 * password) and the time where the client can proceed with the SRP setup (which
 * can only happen once we have an auth token).
 *
 * For example, when the user is signing up for a new account, the client has
 * the KEK on the signup screen since the user just set their password, but then
 * has to redirect to the screen for email verification, and it is only after
 * email verification that the client obtains an auth token and the SRP setup
 * can proceed (at which point it doesn't have access to the password and so
 * cannot derive the KEK).
 *
 * This gap is not just about different screens, but since there is an email
 * verification step involved, it might take time enough for the browser tab to
 * get closed and reopened. So instead of keeping the attributes we need to
 * continue with the SRP setup after email verification in memory, we
 * temporarily stash them in local storage using an object that conforms to the
 * following {@link SRPSetupAttributes} schema.
 */
export const SRPSetupAttributes = z.object({
    srpUserID: z.string(),
    srpSalt: z.string(),
    srpVerifier: z.string(),
    loginSubKey: z.string(),
});

export type SRPSetupAttributes = z.infer<typeof SRPSetupAttributes>;

/**
 * Generate {@link SRPSetupAttributes} from the provided {@link kek}.
 *
 * @param kek The designated key encryption key (base64 encoded) for the user.
 * This will be used to (deterministically) derive a SRP password.
 */
export const generateSRPSetupAttributes = async (
    kek: string,
): Promise<SRPSetupAttributes> => {
    const loginSubKey = await deriveSRPLoginSubKey(kek);

    // Museum schema requires this to be a UUID.
    const srpUserID = uuidv4();
    const srpSalt = await generateDeriveKeySalt();

    const srpVerifier = bufferToB64(
        SRP.computeVerifier(
            SRP.params["4096"],
            b64ToBuffer(srpSalt),
            Buffer.from(srpUserID),
            b64ToBuffer(loginSubKey),
        ),
    );

    return { srpUserID, srpSalt, srpVerifier, loginSubKey };
};

/**
 * Derive a "login sub-key" (which is really an arbitrary binary value, not
 * human generated) for use as the SRP user password by applying a deterministic
 * KDF (Key Derivation Function) to the provided {@link kek}.
 *
 * @param kek The user's KEK (key encryption key) as a base64 string.
 *
 * @returns A base64 encoded key that can be used as the SRP user password.
 */
const deriveSRPLoginSubKey = async (kek: string) => {
    const kekSubKeyBytes = await deriveSubKeyBytes(kek, 32, 1, "loginctx");
    // Use the first 16 bytes (128 bits) of the KEK's KDF subkey as the SRP
    // password (instead of entire 32 bytes).
    return toB64(kekSubKeyBytes.slice(0, 16));
};

const b64ToBuffer = (base64: string) => Buffer.from(base64, "base64");

const bufferToB64 = (buffer: Buffer) => buffer.toString("base64");

/**
 * Use the provided {@link SRPSetupAttributes} to, well, setup SRP.
 *
 * See: [Note: SRP setup]
 *
 * @param srpSetupAttributes SRP setup attributes.
 */
export const setupSRP = async (srpSetupAttributes: SRPSetupAttributes) =>
    srpSetupOrReconfigure(srpSetupAttributes, completeSRPSetup);

/**
 * A function that is called by {@link srpSetupOrReconfigure} to exchange the
 * evidence message M1 for the evidence message M2 from remote.
 *
 * It is passed M1, and is expected to fulfill with M2.
 */
type SRPSetupOrReconfigureExchangeCallback = ({
    setupID,
    srpM1,
}: {
    setupID: string;
    srpM1: string;
}) => Promise<{ srpM2: string }>;

/**
 * Use the provided {@link SRPSetupAttributes} to either setup (afresh) or
 * reconfigure SRP (when the user changes their password).
 *
 * The flow (described in [Note: SRP setup]) is mostly the same except the tail
 * end of the process where we exchange the evidence message M1 for the evidence
 * message M2 from remote. To handle this variance, we provide a callback
 * {@link exchangeCB}) that is invoked at this point in the sequence.
 *
 * @param srpSetupAttributes SRP setup attributes.
 */
const srpSetupOrReconfigure = async (
    { srpSalt, srpUserID, srpVerifier, loginSubKey }: SRPSetupAttributes,
    exchangeCB: SRPSetupOrReconfigureExchangeCallback,
) => {
    const srpClient = await generateSRPClient(srpSalt, srpUserID, loginSubKey);

    const srpA = bufferToB64(srpClient.computeA());

    const { setupID, srpB } = await startSRPSetup({
        srpUserID,
        srpSalt,
        srpVerifier,
        srpA,
    });

    srpClient.setB(b64ToBuffer(srpB));

    const srpM1 = bufferToB64(srpClient.computeM1());

    const { srpM2 } = await exchangeCB({ srpM1, setupID });

    srpClient.checkM2(b64ToBuffer(srpM2));
};

const generateSRPClient = async (
    srpSalt: string,
    srpUserID: string,
    loginSubKey: string,
) =>
    new Promise<SrpClient>((resolve, reject) => {
        SRP.genKey((err, clientKey) => {
            if (err) reject(err);
            resolve(
                new SrpClient(
                    SRP.params["4096"],
                    b64ToBuffer(srpSalt),
                    Buffer.from(srpUserID),
                    b64ToBuffer(loginSubKey),
                    // The random `clientKey` parameterizes the current instance
                    // of the SRP client.
                    clientKey!,
                    false,
                ),
            );
        });
    });

interface SetupSRPRequest {
    srpUserID: string;
    srpSalt: string;
    srpVerifier: string;
    srpA: string;
}

const SetupSRPResponse = z.object({ setupID: z.string(), srpB: z.string() });

type SetupSRPResponse = z.infer<typeof SetupSRPResponse>;

/**
 * Initiate SRP setup on remote.
 *
 * Part of the [Note: SRP setup] sequence.
 */
const startSRPSetup = async (
    setupSRPRequest: SetupSRPRequest,
): Promise<SetupSRPResponse> => {
    const res = await fetch(await apiURL("/users/srp/setup"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify(setupSRPRequest),
    });
    ensureOk(res);
    return SetupSRPResponse.parse(await res.json());
};

interface CompleteSRPSetupRequest {
    setupID: string;
    srpM1: string;
}

const CompleteSRPSetupResponse = z.object({
    setupID: z.string(),
    srpM2: z.string(),
});

type CompleteSRPSetupResponse = z.infer<typeof CompleteSRPSetupResponse>;

/**
 * Complete a previously initiated SRP setup on remote.
 *
 * Part of the [Note: SRP setup] sequence.
 */
const completeSRPSetup = async (
    completeSRPSetupRequest: CompleteSRPSetupRequest,
) => {
    const res = await fetch(await apiURL("/users/srp/complete"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify(completeSRPSetupRequest),
    });
    ensureOk(res);
    return CompleteSRPSetupResponse.parse(await res.json());
};

/**
 * Fetch the SRP attributes from remote and use them to update the SRP
 * attributes we have saved locally.
 *
 * This function is intended to be called after {@link srpSetupOrReconfigure} to
 * also update our local state to match remote.
 *
 * @param userEmail The email of the user whose SRP attributes we want to fetch.
 * This should be the email address of the logged in user, or the user who is
 * going through the login / signup sequence currently.
 */
export const getAndSaveSRPAttributes = async (userEmail: string) =>
    saveSRPAttributes(ensure(await getSRPAttributes(userEmail)));

/**
 * The subset of {@link KeyAttributes} that get updated when the user changes
 * their password.
 */
export interface UpdatedKeyAttr {
    kekSalt: string;
    encryptedKey: string;
    keyDecryptionNonce: string;
    opsLimit: number;
    memLimit: number;
}

/**
 * Update the user's affected key and SRP attributes when they change their
 * password.
 *
 * The flow on changing password is similar to the flow on initial SRP setup,
 * with some differences at the tail end of the flow. See: [Note: SRP setup].
 *
 * @param srpSetupAttributes Attributes for the user's updated SRP setup.
 *
 * @param updatedKeyAttr The subset of the user's key attributes which need to
 * be updated to reflect their changed password.
 */
export const updateSRPAndKeyAttributes = (
    srpSetupAttributes: SRPSetupAttributes,
    updatedKeyAttr: UpdatedKeyAttr,
) =>
    srpSetupOrReconfigure(srpSetupAttributes, ({ setupID, srpM1 }) =>
        updateSRPAndKeys({ setupID, srpM1, updatedKeyAttr }),
    );

export interface UpdateSRPAndKeysRequest {
    setupID: string;
    srpM1: string;
    updatedKeyAttr: UpdatedKeyAttr;
    /**
     * If true (default), then all existing sessions for the user will be
     * invalidated.
     */
    logOutOtherDevices?: boolean;
}

const UpdateSRPAndKeysResponse = z.object({
    srpM2: z.string(),
    setupID: z.string(),
});

type UpdateSRPAndKeysResponse = z.infer<typeof UpdateSRPAndKeysResponse>;

/**
 * Update the SRP attributes and a subset of the key attributes on remote.
 *
 * This is invoked during the flow when the user changes their password, and SRP
 * needs to be reconfigured. See: [Note: SRP setup].
 */
const updateSRPAndKeys = async (
    updateSRPAndKeysRequest: UpdateSRPAndKeysRequest,
): Promise<UpdateSRPAndKeysResponse> => {
    const res = await fetch(await apiURL("/users/srp/update"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify(updateSRPAndKeysRequest),
    });
    ensureOk(res);
    return UpdateSRPAndKeysResponse.parse(await res.json());
};

/**
 * The message of the {@link Error} that is thrown by {@link verifySRP} if
 * remote fails SRP verification with a HTTP 401.
 *
 * The API contract allows for a SRP verification 401 both because of incorrect
 * credentials or a non existent account.
 */
export const srpVerificationUnauthorizedErrorMessage =
    "SRP verification failed (HTTP 401 Unauthorized)";

/**
 * Log the user in to a new device by performing SRP verification.
 *
 * This function implements the flow described in [Note: SRP verification].
 *
 * @param srpAttributes The user's SRP attributes.
 *
 * @param kek The user's key encryption key as a base64 string.
 *
 * @returns If SRP verification is successful, it returns a
 * {@link EmailOrSRPVerificationResponse}.
 *
 * @throws An Error with {@link srpVerificationUnauthorizedErrorMessage} in case
 * there is no such account, or if the credentials (kek) are incorrect.
 */
export const verifySRP = async (
    { srpUserID, srpSalt }: SRPAttributes,
    kek: string,
): Promise<EmailOrSRPVerificationResponse> => {
    const loginSubKey = await deriveSRPLoginSubKey(kek);
    const srpClient = await generateSRPClient(srpSalt, srpUserID, loginSubKey);

    // Send A, obtain B.
    const { srpB, sessionID } = await createSRPSession({
        srpUserID,
        srpA: bufferToB64(srpClient.computeA()),
    });

    srpClient.setB(b64ToBuffer(srpB));

    // Send M1, obtain M2.
    const { srpM2, ...rest } = await verifySRPSession({
        sessionID,
        srpUserID,
        srpM1: bufferToB64(srpClient.computeM1()),
    });

    srpClient.checkM2(b64ToBuffer(srpM2));

    return rest;
};

interface CreateSRPSessionRequest {
    srpUserID: string;
    srpA: string;
}

const CreateSRPSessionResponse = z.object({
    sessionID: z.string(),
    srpB: z.string(),
});

type CreateSRPSessionResponse = z.infer<typeof CreateSRPSessionResponse>;

const createSRPSession = async (
    createSRPSessionRequest: CreateSRPSessionRequest,
): Promise<CreateSRPSessionResponse> => {
    const res = await fetch(await apiURL("/users/srp/create-session"), {
        method: "POST",
        headers: publicRequestHeaders(),
        body: JSON.stringify(createSRPSessionRequest),
    });
    ensureOk(res);
    return CreateSRPSessionResponse.parse(await res.json());
};

interface VerifySRPSessionRequest {
    sessionID: string;
    srpUserID: string;
    srpM1: string;
}

type SRPVerificationResponse = z.infer<typeof RemoteSRPVerificationResponse>;

const verifySRPSession = async (
    verifySRPSessionRequest: VerifySRPSessionRequest,
): Promise<SRPVerificationResponse> => {
    const res = await fetch(await apiURL("/users/srp/verify-session"), {
        method: "POST",
        headers: publicRequestHeaders(),
        body: JSON.stringify(verifySRPSessionRequest),
    });
    if (res.status == 401) {
        throw new Error(srpVerificationUnauthorizedErrorMessage);
    }
    ensureOk(res);
    return RemoteSRPVerificationResponse.parse(await res.json());
};
