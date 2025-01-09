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
    Box,
    Button,
    ButtonBase,
    Snackbar,
    Stack,
    TextField,
    Typography,
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
        <Stack>
            <AuthNavbar />
            <Stack
                sx={{
                    maxWidth: "800px",
                    alignItems: "center",
                    justifyContent: "center",
                    margin: "0 auto",
                    mt: 1,
                }}
            >
                {filteredCodes.length == 0 && searchTerm.length == 0 ? (
                    <></>
                ) : (
                    <TextField
                        id="search"
                        name="search"
                        label={t("search")}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        variant="filled"
                        sx={{ minWidth: "min(340px, 80svw)" }}
                        value={searchTerm}
                        autoFocus
                    />
                )}

                <Box
                    sx={{
                        display: "flex",
                        flexDirection: "row",
                        flexWrap: "wrap",
                        justifyContent: "center",
                        mt: 3,
                    }}
                >
                    {filteredCodes.length == 0 ? (
                        <Box sx={{ textAlign: "center", mt: 4 }}>
                            {searchTerm.length > 0 ? (
                                <Typography>{t("no_results")}</Typography>
                            ) : (
                                <Typography sx={{ color: "text.muted" }}>
                                    {t("no_codes_added_yet")}
                                </Typography>
                            )}
                        </Box>
                    ) : (
                        filteredCodes.map((code) => (
                            <CodeDisplay key={code.id} code={code} />
                        ))
                    )}
                </Box>
                <Footer />
            </Stack>
        </Stack>
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
        <Box sx={{ p: 1 }}>
            {errorMessage ? (
                <UnparseableCode {...{ code, errorMessage }} />
            ) : (
                <ButtonBase component="div" onClick={copyCode}>
                    <OTPDisplay {...{ code, otp, nextOTP }} />
                    <Snackbar open={hasCopied} message={t("copied")} />
                </ButtonBase>
            )}
        </Box>
    );
};

interface OTPDisplayProps {
    code: Code;
    otp: string;
    nextOTP: string;
}

const OTPDisplay: React.FC<OTPDisplayProps> = ({ code, otp, nextOTP }) => {
    return (
        <Box
            sx={(theme) => ({
                backgroundColor: theme.palette.background.paper,
                borderRadius: "4px",
                overflow: "hidden",
            })}
        >
            <CodeValidityBar code={code} />
            <Stack
                direction="row"
                sx={{
                    padding: "12px 20px 0px 20px",
                    minWidth: "min(360px, 80svw)",
                    minHeight: "120px",
                    justifyContent: "space-between",
                }}
            >
                <Stack style={{ gap: "4px", alignItems: "flex-start" }}>
                    <Typography variant="small">{code.issuer}</Typography>
                    <Typography
                        variant="mini"
                        sx={{ color: "text.faint", flex: 1, minHeight: "16px" }}
                    >
                        {code.account ?? ""}
                    </Typography>
                    <Typography variant="h3" sx={{ mb: "20px" }}>
                        {otp}
                    </Typography>
                </Stack>
                <Stack
                    sx={{
                        justifyContent: "flex-end",
                        alignItems: "flex-end",
                        textAlign: "right",
                        mb: "1rem",
                        gap: "2px",
                    }}
                >
                    <Typography variant="mini" sx={{ color: "text.faint" }}>
                        {t("auth_next")}
                    </Typography>
                    <Typography
                        variant="small"
                        sx={{ fontWeight: "medium", color: "text.muted" }}
                    >
                        {nextOTP}
                    </Typography>
                </Stack>
            </Stack>
        </Box>
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
        <Stack sx={{ my: "4rem", gap: 2, alignItems: "center" }}>
            <Typography>{t("auth_download_mobile_app")}</Typography>
            <a
                href="https://github.com/ente-io/ente/tree/main/auth#-download"
                download
            >
                <Button color="accent">{t("download")}</Button>
            </a>
        </Stack>
    );
};
