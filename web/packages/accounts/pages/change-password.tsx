import { Divider } from "@mui/material";
import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "ente-accounts/components/layouts/centered-paper";
import { appHomeRoute, stashRedirect } from "ente-accounts/services/redirect";
import {
    changePassword,
    localUser,
    type LocalUser,
} from "ente-accounts/services/user";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingIndicator } from "ente-base/components/loaders";
import { deriveKeyInsufficientMemoryErrorMessage } from "ente-base/crypto/types";
import log from "ente-base/log";
import { getData, setData } from "ente-shared/storage/localStorage";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useState } from "react";
import {
    NewPasswordForm,
    type NewPasswordFormProps,
} from "../components/NewPasswordForm";

/**
 * A page that allows a user to reset or change their password.
 */
const Page: React.FC = () => {
    const [user, setUser] = useState<LocalUser>();

    const router = useRouter();

    useEffect(() => {
        const user = localUser();
        if (user) {
            setUser(user);
        } else {
            stashRedirect("/change-password");
            void router.push("/");
        }
    }, [router]);

    return user ? <PageContents {...{ user }} /> : <LoadingIndicator />;
};

export default Page;

interface PageContentsProps {
    user: LocalUser;
}

const PageContents: React.FC<PageContentsProps> = ({ user }) => {
    const router = useRouter();

    const redirectToAppHome = useCallback(() => {
        setData("showBackButton", { value: true });
        void router.push(appHomeRoute);
    }, [router]);

    const handleSubmit: NewPasswordFormProps["onSubmit"] = async (
        password,
        setPasswordsFieldError,
    ) =>
        changePassword(password)
            .then(redirectToAppHome)
            .catch((e: unknown) => {
                log.error("Could not change password", e);
                setPasswordsFieldError(
                    e instanceof Error &&
                        e.message == deriveKeyInsufficientMemoryErrorMessage
                        ? t("password_generation_failed")
                        : t("generic_error"),
                );
            });

    return (
        <AccountsPageContents>
            <AccountsPageTitle>{t("change_password")}</AccountsPageTitle>
            <NewPasswordForm
                userEmail={user.email}
                submitButtonTitle={t("change_password")}
                onSubmit={handleSubmit}
            />
            {(getData("showBackButton")?.value ?? true) && (
                <>
                    <Divider sx={{ mt: 1 }} />
                    <AccountsPageFooter>
                        <LinkButton onClick={router.back}>
                            {t("go_back")}
                        </LinkButton>
                    </AccountsPageFooter>
                </>
            )}
        </AccountsPageContents>
    );
};
