import { isDevBuild } from "@/next/env";
import EnteButton from "@ente/shared/components/EnteButton";
import { apiOrigin } from "@ente/shared/network/api";
import { Typography, styled } from "@mui/material";
import { t } from "i18next";
import { VerticallyCentered } from "./Container";
import FormPaper from "./Form/FormPaper";
import FormPaperFooter from "./Form/FormPaper/Footer";
import LinkButton from "./LinkButton";

export const PasswordHeader: React.FC<React.PropsWithChildren> = ({
    children,
}) => {
    return (
        <Header_>
            <Typography variant="h2">{t("password")}</Typography>
            <Typography color="text.faint">{children}</Typography>
        </Header_>
    );
};

const PasskeyHeader: React.FC<React.PropsWithChildren> = ({ children }) => {
    return (
        <Header_>
            <Typography variant="h3">{"Passkey"}</Typography>
            <Typography color="text.faint">{children}</Typography>
        </Header_>
    );
};

const Header_ = styled("div")`
    margin-block-end: 4rem;
    display: flex;
    flex-direction: column;
    gap: 8px;
`;

export const ConnectionDetails: React.FC = () => {
    const host = new URL(apiOrigin()).host;

    return (
        <ConnectionDetails_>
            <Typography variant="small" color="text.faint">
                {host}
            </Typography>
        </ConnectionDetails_>
    );
};

const ConnectionDetails_ = styled("div")`
    margin-block-start: 1rem;
`;

interface VerifyingPasskeyProps {
    /** The email of the user whose passkey we're verifying */
    email: string | undefined;
    /** Called when the user wants to redirect again. */
    onRetry: () => void;
    /** Called when the user presses the "Recover account" button. */
    onRecover: () => void;
    /** Called when the user presses the "Change email" button. */
    onLogout: () => void;
}

export const VerifyingPasskey: React.FC<VerifyingPasskeyProps> = ({
    email,
    onRetry,
    onRecover,
    onLogout,
}) => {
    return (
        <VerticallyCentered>
            <FormPaper style={{ minWidth: "320px" }}>
                <PasskeyHeader>{email ?? ""} </PasskeyHeader>

                <VerifyingPasskeyMiddle>
                    <Typography>{t("waiting_for_verification")}</Typography>

                    <EnteButton onClick={onRetry} color="accent" type="button">
                        {t("redirect_again")}
                    </EnteButton>
                </VerifyingPasskeyMiddle>

                <FormPaperFooter style={{ justifyContent: "space-between" }}>
                    <LinkButton onClick={onRecover}>
                        {t("RECOVER_ACCOUNT")}
                    </LinkButton>
                    <LinkButton onClick={onLogout}>
                        {t("CHANGE_EMAIL")}
                    </LinkButton>
                </FormPaperFooter>

                {isDevBuild && <ConnectionDetails />}
            </FormPaper>
        </VerticallyCentered>
    );
};

const VerifyingPasskeyMiddle = styled("div")`
    display: flex;
    flex-direction: column;

    margin-block: 3rem;
    gap: 3rem;
    align-items: center;
`;
