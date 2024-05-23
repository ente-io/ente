import {
    HorizontalFlex,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import { EnteLogo } from "@ente/shared/components/EnteLogo";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import NavbarBase from "@ente/shared/components/Navbar/base";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import { AUTH_PAGES as PAGES } from "@ente/shared/constants/pages";
import { CustomError } from "@ente/shared/error";
import InMemoryStore, { MS_KEYS } from "@ente/shared/storage/InMemoryStore";
import LogoutOutlined from "@mui/icons-material/LogoutOutlined";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import { Button, ButtonBase, Snackbar, TextField } from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import React, { useContext, useEffect, useState } from "react";
import { generateOTPs, type Code } from "services/code";
import { getAuthCodes } from "services/remote";

const AuthenticatorCodesPage = () => {
    const appContext = useContext(AppContext);
    const router = useRouter();
    const [codes, setCodes] = useState([]);
    const [hasFetched, setHasFetched] = useState(false);
    const [searchTerm, setSearchTerm] = useState("");

    useEffect(() => {
        const fetchCodes = async () => {
            try {
                const res = await getAuthCodes();
                setCodes(res);
            } catch (err) {
                if (err.message === CustomError.KEY_MISSING) {
                    InMemoryStore.set(MS_KEYS.REDIRECT_URL, PAGES.AUTH);
                    router.push(PAGES.ROOT);
                } else {
                    // do not log errors
                }
            }
            setHasFetched(true);
        };
        void fetchCodes();
        appContext.showNavBar(false);
    }, []);

    const filteredCodes = codes.filter(
        (secret) =>
            (secret.issuer ?? "")
                .toLowerCase()
                .includes(searchTerm.toLowerCase()) ||
            (secret.account ?? "")
                .toLowerCase()
                .includes(searchTerm.toLowerCase()),
    );

    if (!hasFetched) {
        return (
            <>
                <VerticallyCentered>
                    <EnteSpinner></EnteSpinner>
                </VerticallyCentered>
            </>
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
                {filteredCodes.length === 0 && searchTerm.length === 0 ? (
                    <></>
                ) : (
                    <TextField
                        id="search"
                        name="search"
                        label={t("SEARCH")}
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
                    {filteredCodes.length === 0 ? (
                        <div
                            style={{
                                alignItems: "center",
                                display: "flex",
                                textAlign: "center",
                                marginTop: "32px",
                            }}
                        >
                            {searchTerm.length !== 0 ? (
                                <p>{t("NO_RESULTS")}</p>
                            ) : (
                                <div />
                            )}
                        </div>
                    ) : (
                        filteredCodes.map((code) => (
                            <CodeDisplay key={code.id} code={code} />
                        ))
                    )}
                </div>
                <div style={{ marginBottom: "2rem" }} />
                <Footer />
                <div style={{ marginBottom: "4rem" }} />
            </div>
        </>
    );
};

export default AuthenticatorCodesPage;

const AuthNavbar: React.FC = () => {
    const { isMobile, logout } = useContext(AppContext);

    return (
        <NavbarBase isMobile={isMobile}>
            <HorizontalFlex flex={1} justifyContent={"center"}>
                <EnteLogo />
            </HorizontalFlex>
            <HorizontalFlex position={"absolute"} right="24px">
                <OverflowMenu
                    ariaControls={"auth-options"}
                    triggerButtonIcon={<MoreHoriz />}
                >
                    <OverflowMenuOption
                        color="critical"
                        startIcon={<LogoutOutlined />}
                        onClick={logout}
                    >
                        {t("LOGOUT")}
                    </OverflowMenuOption>
                </OverflowMenu>
            </HorizontalFlex>
        </NavbarBase>
    );
};

interface CodeDisplay {
    code: Code;
}

const CodeDisplay: React.FC<CodeDisplay> = ({ code }) => {
    const [otp, setOTP] = useState("");
    const [nextOTP, setNextOTP] = useState("");
    const [errorMessage, setErrorMessage] = useState("");
    const [hasCopied, setHasCopied] = useState(false);

    const regen = () => {
        try {
            const [m, n] = generateOTPs(code);
            setOTP(m);
            setNextOTP(n);
        } catch (e) {
            setErrorMessage(e instanceof Error ? e.message : String(e));
        }
    };

    const copyCode = () => {
        navigator.clipboard.writeText(otp);
        setHasCopied(true);
        setTimeout(() => setHasCopied(false), 2000);
    };

    useEffect(() => {
        // Generate to set the initial otp and nextOTP on component mount.
        regen();
        const codeType = code.type;
        const codePeriodInMs = code.period * 1000;
        const timeToNextCode =
            codePeriodInMs - (new Date().getTime() % codePeriodInMs);
        const interval = null;
        // Wait until we are at the start of the next code period, and then
        // start the interval loop.
        setTimeout(() => {
            // We need to call regen() once before the interval loop to set the
            // initial otp and nextOTP.
            regen();
            codeType.toLowerCase() === "totp" ||
            codeType.toLowerCase() === "hotp"
                ? setInterval(() => {
                      regen();
                  }, codePeriodInMs)
                : null;
        }, timeToNextCode);

        return () => {
            if (interval) clearInterval(interval);
        };
    }, [code]);

    return (
        <div style={{ padding: "8px" }}>
            {errorMessage ? (
                <UnparseableCode {...{ code, errorMessage }} />
            ) : (
                <ButtonBase component="div" onClick={copyCode}>
                    <OTPDisplay {...{ code, otp, nextOTP }} />
                    <Snackbar open={hasCopied} message={t("COPIED")} />
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
            <TimerProgress period={code.period} />
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
                        {code.account}
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
                        {t("AUTH_NEXT")}
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

interface TimerProgressProps {
    period: number;
}

const TimerProgress: React.FC<TimerProgressProps> = ({ period }) => {
    const [progress, setProgress] = useState(0);
    const us = period * 1e6;

    useEffect(() => {
        const advance = () => {
            const timeRemaining = us - ((new Date().getTime() * 1000) % us);
            setProgress(timeRemaining / us);
        };

        const ticker = setInterval(advance, 10);

        return () => clearInterval(ticker);
    }, []);

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
        <div
            style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
            }}
        >
            <p>{t("AUTH_DOWNLOAD_MOBILE_APP")}</p>
            <a
                href="https://github.com/ente-io/ente/tree/main/auth#-download"
                download
            >
                <Button color="accent">{t("DOWNLOAD")}</Button>
            </a>
        </div>
    );
};
