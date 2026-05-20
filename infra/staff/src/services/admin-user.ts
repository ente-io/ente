import { z } from "zod";
import {
    apiURL,
    ensureOk,
    requireEmail,
    staffJSONRequestHeaders,
    staffRequestHeaders,
} from "./api";
import type { StaffSession } from "./session";

const UserProfileData = z.looseObject({
    isEmailMFAEnabled: z.boolean(),
    isTwoFactorEnabled: z.boolean(),
    passkeyCount: z.number(),
    canDisableEmailMFA: z.boolean(),
});

const FamilyMember = z.looseObject({
    id: z.string(),
    email: z.string(),
    status: z.string(),
    usage: z.number(),
    storageLimit: z.number().optional(),
});

export type FamilyMember = z.infer<typeof FamilyMember>;

const StorageBonus = z.looseObject({
    storage: z.number(),
    type: z.string(),
    createdAt: z.number(),
    validTill: z.number(),
    isRevoked: z.boolean(),
});

export type StorageBonus = z.infer<typeof StorageBonus>;

const TokenData = z.looseObject({
    creationTime: z.number(),
    lastUsedTime: z.number(),
    ua: z.string(),
    isDeleted: z.boolean(),
    app: z.string(),
});

export type TokenData = z.infer<typeof TokenData>;

const Subscription = z.looseObject({
    productID: z.string(),
    paymentProvider: z.string(),
    storage: z.number(),
    originalTransactionID: z.string(),
    expiryTime: z.number(),
    userID: z.number(),
    attributes: z.looseObject({
        customerID: z.string().optional(),
        stripeAccountCountry: z.string().optional(),
    }),
});

export type Subscription = z.infer<typeof Subscription>;

const UserResponse = z.looseObject({
    user: z.looseObject({
        ID: z.number(),
        email: z.string(),
        creationTime: z.number(),
    }),
    subscription: Subscription.nullable().optional(),
    authCodes: z.number().optional(),
    tokens: z.array(TokenData).optional(),
    details: z
        .looseObject({
            usage: z.number(),
            storageBonus: z.number(),
            profileData: UserProfileData.nullish(),
            familyData: z
                .looseObject({ members: z.array(FamilyMember) })
                .optional(),
            bonusData: z
                .looseObject({ storageBonuses: z.array(StorageBonus) })
                .nullish(),
        })
        .optional(),
});

export type UserResponse = z.infer<typeof UserResponse>;

interface AddOTTRequest {
    email: string;
    code: string;
    app: string;
    expiryTime: number;
}

export interface UpdateSubscriptionRequest {
    userID: number;
    storage: number;
    expiryTime: number;
    productID: string;
    paymentProvider: string;
    transactionID: string;
    attributes: { customerID: string; stripeAccountCountry: string };
}

const userSearchQuery = (input: string) => {
    const trimmedInput = input.trim();
    if (/^\d+$/.test(trimmedInput)) {
        return { id: trimmedInput };
    }
    return { email: trimmedInput };
};

export const getUser = async (
    session: Pick<StaffSession, "token">,
    input: string,
) => {
    if (!input.trim()) {
        throw new Error("Enter an email or user ID");
    }

    const response = await fetch(
        apiURL("/admin/user", userSearchQuery(input)),
        { headers: staffJSONRequestHeaders(session) },
    );
    if (response.status === 401) {
        throw new Error("Invalid token");
    }
    if (response.status === 403) {
        throw new Error("Insufficient permissions");
    }
    if (response.status === 404) {
        throw new Error("User not found");
    }

    await ensureOk(response, "Network response was not ok");
    return UserResponse.parse(await response.json());
};

export const getSelectedUser = async (session: StaffSession) => {
    const response = await fetch(
        apiURL("/admin/user", { email: requireEmail(session) }),
        { headers: staffJSONRequestHeaders(session) },
    );
    await ensureOk(response, "Failed to fetch user data");
    return UserResponse.parse(await response.json());
};

export const getSelectedUserID = async (session: StaffSession) => {
    const userData = await getSelectedUser(session);
    const userID = userData.subscription?.userID;
    if (userID === undefined) throw new Error("User ID not found");
    return userID;
};

export const getSelectedSubscription = async (session: StaffSession) => {
    const userData = await getSelectedUser(session);
    if (!userData.subscription) {
        throw new Error("Subscription data not found");
    }
    return userData.subscription;
};

export const getFamilyMembers = async (session: StaffSession) => {
    const userData = await getSelectedUser(session);
    return userData.details?.familyData?.members ?? [];
};

export const getStorageBonuses = async (session: StaffSession) => {
    const userData = await getSelectedUser(session);
    return userData.details?.bonusData?.storageBonuses ?? [];
};

export const getTokens = async (session: StaffSession) => {
    const userData = await getSelectedUser(session);
    return userData.tokens ?? [];
};

export const addOTT = async (
    session: StaffSession,
    { app, code, email, expiryTime }: AddOTTRequest,
) => {
    const response = await fetch(apiURL("/admin/user/add-ott"), {
        method: "POST",
        headers: staffJSONRequestHeaders(session),
        body: JSON.stringify({ email, code, app, expiryTime }),
    });
    await ensureOk(response, "Failed to create OTT");
};

export const changeUserEmail = async (
    session: StaffSession,
    userID: number,
    email: string,
) => {
    const response = await fetch(apiURL("/admin/user/change-email"), {
        method: "PUT",
        headers: staffJSONRequestHeaders(session),
        body: JSON.stringify({ userID, email }),
    });
    await ensureOk(response, "Network response was not ok");
};

export const closeFamily = async (session: StaffSession) => {
    const userID = await getSelectedUserID(session);
    const response = await fetch(apiURL("/admin/user/close-family"), {
        method: "POST",
        headers: staffJSONRequestHeaders(session),
        body: JSON.stringify({ userID }),
    });
    await ensureOk(response, "Failed to close family");
};

export const deleteAccount = async (session: StaffSession) => {
    const response = await fetch(
        apiURL("/admin/user/delete", { email: requireEmail(session) }),
        { method: "DELETE", headers: staffRequestHeaders(session) },
    );
    await ensureOk(response, "Failed to delete user account");
};

export const disable2FA = async (session: StaffSession) => {
    const userID = await getSelectedUserID(session);
    const response = await fetch(apiURL("/admin/user/disable-2fa"), {
        method: "POST",
        headers: staffJSONRequestHeaders(session),
        body: JSON.stringify({ userID }),
    });
    await ensureOk(response, "Failed to disable 2FA");
};

export const disablePasskeys = async (session: StaffSession) => {
    const userID = await getSelectedUserID(session);
    const response = await fetch(apiURL("/admin/user/disable-passkeys"), {
        method: "POST",
        headers: staffJSONRequestHeaders(session),
        body: JSON.stringify({ userID }),
    });
    await ensureOk(response, "Failed to disable passkeys");
};

export const updateEmailMFA = async (
    session: StaffSession,
    emailMFA: boolean,
) => {
    const userID = await getSelectedUserID(session);
    const response = await fetch(apiURL("/admin/user/update-email-mfa"), {
        method: "POST",
        headers: staffJSONRequestHeaders(session),
        body: JSON.stringify({ userID, emailMFA }),
    });
    await ensureOk(response, "Failed to update Email MFA");
};

export const updateUserSubscription = async (
    session: StaffSession,
    request: UpdateSubscriptionRequest,
) => {
    const response = await fetch(apiURL("/admin/user/subscription"), {
        method: "PUT",
        headers: staffJSONRequestHeaders(session),
        body: JSON.stringify(request),
    });
    await ensureOk(response, "Network response was not ok");
};
