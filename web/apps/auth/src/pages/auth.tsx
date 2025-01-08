import { sessionExpiredDialogAttributes } from "@/accounts/components/utils/dialog";
import { stashRedirect } from "@/accounts/services/redirect";
import { EnteLogo } from "@/base/components/EnteLogo";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { NavbarBase } from "@/base/components/Navbar";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "@/base/components/OverflowMenu";
import { isHTTP401Error } from "@/base/http";
import log from "@/base/log";
import { masterKeyFromSessionIfLoggedIn } from "@/base/session-store";
import { VerticallyCentered } from "@ente/shared/components/Container";
import { AUTH_PAGES as PAGES } from "@ente/shared/constants/pages";
import LogoutOutlinedIcon from "@mui/icons-material/LogoutOutlined";
import {
    Button,
    ButtonBase,
    Snackbar,
    Stack,
    TextField,
    Typography,
    styled,
} from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useState } from "react";
import { generateOTPs, type Code } from "services/code";
import { getAuthCodes } from "services/remote";
import { useAppContext } from "types/context";

const Page: React.FC = () => {
    const { logout, showNavBar, showMiniDialog } = useAppContext();

    const router = useRouter();
    const [codes, setCodes] = useState<Code[]>([]);
    const [hasFetched, setHasFetched] = useState(false);
    const [searchTerm, setSearchTerm] = useState("");

    useEffect(() => {
        const fetchCodes = async () => {
            const masterKey = await masterKeyFromSessionIfLoggedIn();
            if (!masterKey) {
                stashRedirect(PAGES.AUTH);
                void router.push("/");
                return;
            }

            try {
                setCodes(await getAuthCodes(masterKey));
            } catch (e) {
                log.error("Failed to fetch codes", e);
                if (isHTTP401Error(e))
                    showMiniDialog(sessionExpiredDialogAttributes(logout));
            }
            setHasFetched(true);
        };
        void fetchCodes();
        showNavBar(false);
    }, [router, showNavBar, showMiniDialog, logout]);

    const lcSearch = searchTerm.toLowerCase();
    const filteredCodes = codes.filter(
        (code) =>
            code.issuer.toLowerCase().includes(lcSearch) ||
            code.account?.toLowerCase().includes(lcSearch),
    );

    if (!hasFetched) {
        return (
            <VerticallyCentered>
                <ActivityIndicator />
            </VerticallyCentered>
        );
    }

    return (
        <>
            <AuthNavbar />
            <div
                style={{
                    maxWidth: "800px",
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    justifyContent: "center",
                    margin: "0 auto",
                }}
            >
                <div style={{ marginBottom: "1rem" }} />
                {filteredCodes.length == 0 && searchTerm.length == 0 ? (
                    <></>
                ) : (
                    <TextField
                        id="search"
                        name="search"
                        label={t("search")}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        variant="filled"
                        style={{ width: "350px" }}
                        value={searchTerm}
                        autoFocus
                    />
                )}

                <div style={{ marginBottom: "1rem" }} />
                <div
                    style={{
                        display: "flex",
                        flexDirection: "row",
                        flexWrap: "wrap",
                        justifyContent: "center",
                    }}
                >
                    {filteredCodes.length == 0 ? (
                        <div
                            style={{
                                alignItems: "center",
                                display: "flex",
                                textAlign: "center",
                                marginTop: "32px",
                            }}
                        >
                            {searchTerm.length > 0 ? (
                                <Typography>{t("no_results")}</Typography>
                            ) : (
                                <Typography sx={{ color: "text.muted" }}>
                                    {t("no_codes_added_yet")}
                                </Typography>
                            )}
                        </div>
                    ) : (
                        filteredCodes.map((code) => (
                            <CodeDisplay key={code.id} code={code} />
                        ))
                    )}
                </div>
                <Footer />
            </div>
        </>
    );
};

export default Page;

const AuthNavbar: React.FC = () => {
    const { logout } = useAppContext();

    return (
        <NavbarBase>
            <Stack direction="row" sx={{ flex: 1, justifyContent: "center" }}>
                <EnteLogo />
            </Stack>
            <Stack direction="row" sx={{ position: "absolute", right: "24px" }}>
                <OverflowMenu ariaID="auth-options">
                    <OverflowMenuOption
                        color="critical"
                        startIcon={<LogoutOutlinedIcon />}
                        onClick={logout}
                    >
                        {t("logout")}
                    </OverflowMenuOption>
                </OverflowMenu>
            </Stack>
        </NavbarBase>
    );
};

interface CodeDisplayProps {
    code: Code;
}

const CodeDisplay: React.FC<CodeDisplayProps> = ({ code }) => {
    const [otp, setOTP] = useState("");
    const [nextOTP, setNextOTP] = useState("");
    const [errorMessage, setErrorMessage] = useState("");
    const [hasCopied, setHasCopied] = useState(false);

    const regen = useCallback(() => {
        try {
            const [m, n] = generateOTPs(code);
            setOTP(m);
            setNextOTP(n);
        } catch (e) {
            setErrorMessage(e instanceof Error ? e.message : String(e));
        }
    }, [code]);

    const copyCode = () =>
        void navigator.clipboard.writeText(otp).then(() => {
            setHasCopied(true);
            setTimeout(() => setHasCopied(false), 2000);
        });

    useEffect(() => {
        // Generate to set the initial otp and nextOTP on component mount.
        regen();

        const periodMs = code.period * 1000;
        const timeToNextCode = periodMs - (Date.now() % periodMs);

        let interval: ReturnType<typeof setInterval> | undefined;
        // Wait until we are at the start of the next code period, and then
        // start the interval loop.
        setTimeout(() => {
            // We need to call regen() once before the interval loop to set the
            // initial otp and nextOTP.
            regen();
            interval = setInterval(regen, periodMs);
        }, timeToNextCode);

        return () => interval && clearInterval(interval);
    }, [code, regen]);

    return (
        <div style={{ padding: "8px" }}>
            {errorMessage ? (
                <UnparseableCode {...{ code, errorMessage }} />
            ) : (
                <ButtonBase component="div" onClick={copyCode}>
                    <OTPDisplay {...{ code, otp, nextOTP }} />
                    <Snackbar open={hasCopied} message={t("copied")} />
                </ButtonBase>
            )}
        </div>
    );
};

interface OTPDisplayProps {
    code: Code;
    otp: string;
    nextOTP: string;
}

const OTPDisplay: React.FC<OTPDisplayProps> = ({ code, otp, nextOTP }) => {
    return (
        <div
            style={{
                backgroundColor: "rgba(40, 40, 40, 0.6)",
                borderRadius: "4px",
                overflow: "hidden",
            }}
        >
            <CodeValidityBar code={code} />
            <div
                style={{
                    padding: "12px 20px 0px 20px",
                    display: "flex",
                    alignItems: "flex-start",
                    minWidth: "320px",
                    minHeight: "120px",
                    justifyContent: "space-between",
                }}
            >
                <div
                    style={{
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "flex-start",
                        minWidth: "200px",
                    }}
                >
                    <p
                        style={{
                            fontWeight: "bold",
                            margin: "0px",
                            fontSize: "14px",
                            textAlign: "left",
                        }}
                    >
                        {code.issuer}
                    </p>
                    <p
                        style={{
                            marginTop: "0px",
                            marginBottom: "8px",
                            textAlign: "left",
                            fontSize: "12px",
                            maxWidth: "200px",
                            minHeight: "16px",
                            color: "grey",
                        }}
                    >
                        {code.account ?? ""}
                    </p>
                    <p
                        style={{
                            margin: "0px",
                            marginBottom: "1rem",
                            fontSize: "24px",
                            fontWeight: "bold",
                            textAlign: "left",
                        }}
                    >
                        {otp}
                    </p>
                </div>
                <div style={{ flex: 1 }} />
                <div
                    style={{
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "flex-end",
                        minWidth: "120px",
                        textAlign: "right",
                        marginTop: "auto",
                        marginBottom: "1rem",
                    }}
                >
                    <p
                        style={{
                            fontWeight: "bold",
                            marginBottom: "0px",
                            fontSize: "10px",
                            marginTop: "auto",
                            textAlign: "right",
                            color: "grey",
                        }}
                    >
                        {t("auth_next")}
                    </p>
                    <p
                        style={{
                            fontSize: "14px",
                            fontWeight: "bold",
                            marginBottom: "0px",
                            marginTop: "auto",
                            textAlign: "right",
                            color: "grey",
                        }}
                    >
                        {nextOTP}
                    </p>
                </div>
            </div>
        </div>
    );
};

interface CodeValidityBarProps {
    code: Code;
}

const CodeValidityBar: React.FC<CodeValidityBarProps> = ({ code }) => {
    const [progress, setProgress] = useState(code.type == "hotp" ? 1 : 0);

    useEffect(() => {
        const advance = () => {
            const us = code.period * 1e6;
            const timeRemaining = us - ((Date.now() * 1000) % us);
            setProgress(timeRemaining / us);
        };

        const ticker =
            code.type == "hotp" ? undefined : setInterval(advance, 10);

        return () => ticker && clearInterval(ticker);
    }, [code]);

    const color = progress > 0.4 ? "green" : "orange";

    return (
        <div
            style={{
                borderTopLeftRadius: "3px",
                width: `${progress * 100}%`,
                height: "3px",
                backgroundColor: color,
            }}
        />
    );
};

interface UnparseableCodeProps {
    code: Code;
    errorMessage: string;
}

const UnparseableCode: React.FC<UnparseableCodeProps> = ({
    code,
    errorMessage,
}) => {
    const [showRawData, setShowRawData] = useState(false);

    return (
        <div className="code-info">
            <div>{code.issuer}</div>
            <div>{errorMessage}</div>
            <div>
                {showRawData ? (
                    <div onClick={() => setShowRawData(false)}>
                        {code.uriString}
                    </div>
                ) : (
                    <div onClick={() => setShowRawData(true)}>Show rawData</div>
                )}
            </div>
        </div>
    );
};

const Footer: React.FC = () => {
    return (
        <Footer_>
            <Typography>{t("auth_download_mobile_app")}</Typography>
            <a
                href="https://github.com/ente-io/ente/tree/main/auth#-download"
                download
            >
                <Button color="accent">{t("download")}</Button>
            </a>
        </Footer_>
    );
};

const Footer_ = styled("div")`
    margin-block: 4rem;
    display: flex;
    gap: 1rem;
    flex-direction: column;
    align-items: center;
    justify-content: center;
`;
