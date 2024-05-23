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
import { HOTP, TOTP } from "otpauth";
import { AppContext } from "pages/_app";
import React, { useContext, useEffect, useState } from "react";
import { Code } from "services/code";
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
        fetchCodes();
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
                            <OTPDisplay codeInfo={code} key={code.id} />
                        ))
                    )}
                </div>
                <div style={{ marginBottom: "2rem" }} />
                <AuthFooter />
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

const AuthFooter: React.FC = () => {
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

const TOTPDisplay = ({ issuer, account, code, nextCode, period }) => {
    return (
        <div
            style={{
                backgroundColor: "rgba(40, 40, 40, 0.6)",
                borderRadius: "4px",
                overflow: "hidden",
            }}
        >
            <TimerProgress period={period ?? Code.defaultPeriod} />
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
                        {issuer}
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
                        {account}
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
                        {code}
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
                        {nextCode}
                    </p>
                </div>
            </div>
        </div>
    );
};

function BadCodeInfo({ codeInfo, codeErr }) {
    const [showRawData, setShowRawData] = useState(false);

    return (
        <div className="code-info">
            <div>{codeInfo.title}</div>
            <div>{codeErr}</div>
            <div>
                {showRawData ? (
                    <div onClick={() => setShowRawData(false)}>
                        {codeInfo.rawData ?? "no raw data"}
                    </div>
                ) : (
                    <div onClick={() => setShowRawData(true)}>Show rawData</div>
                )}
            </div>
        </div>
    );
}

interface OTPDisplayProps {
    codeInfo: Code;
}

const OTPDisplay: React.FC<OTPDisplayProps> = ({ codeInfo }) => {
    const [code, setCode] = useState("");
    const [nextCode, setNextCode] = useState("");
    const [codeErr, setCodeErr] = useState("");
    const [hasCopied, setHasCopied] = useState(false);

    const generateCodes = () => {
        try {
            const currentTime = new Date().getTime();
            if (codeInfo.type.toLowerCase() === "totp") {
                const totp = new TOTP({
                    secret: codeInfo.secret,
                    algorithm: codeInfo.algorithm ?? Code.defaultAlgo,
                    period: codeInfo.period ?? Code.defaultPeriod,
                    digits: codeInfo.digits ?? Code.defaultDigits,
                });
                setCode(totp.generate());
                setNextCode(
                    totp.generate({
                        timestamp: currentTime + codeInfo.period * 1000,
                    }),
                );
            } else if (codeInfo.type.toLowerCase() === "hotp") {
                const hotp = new HOTP({
                    secret: codeInfo.secret,
                    counter: 0,
                    algorithm: codeInfo.algorithm,
                });
                setCode(hotp.generate());
                setNextCode(hotp.generate({ counter: 1 }));
            }
        } catch (err) {
            setCodeErr(err.message);
        }
    };

    const copyCode = () => {
        navigator.clipboard.writeText(code);
        setHasCopied(true);
        setTimeout(() => {
            setHasCopied(false);
        }, 2000);
    };

    useEffect(() => {
        // this is to set the initial code and nextCode on component mount
        generateCodes();
        const codeType = codeInfo.type;
        const codePeriodInMs = codeInfo.period * 1000;
        const timeToNextCode =
            codePeriodInMs - (new Date().getTime() % codePeriodInMs);
        const intervalId = null;
        // wait until we are at the start of the next code period,
        // and then start the interval loop
        setTimeout(() => {
            // we need to call generateCodes() once before the interval loop
            // to set the initial code and nextCode
            generateCodes();
            codeType.toLowerCase() === "totp" ||
            codeType.toLowerCase() === "hotp"
                ? setInterval(() => {
                      generateCodes();
                  }, codePeriodInMs)
                : null;
        }, timeToNextCode);

        return () => {
            if (intervalId) clearInterval(intervalId);
        };
    }, [codeInfo]);

    return (
        <div style={{ padding: "8px" }}>
            {codeErr === "" ? (
                <ButtonBase
                    component="div"
                    onClick={() => {
                        copyCode();
                    }}
                >
                    <TOTPDisplay
                        period={codeInfo.period}
                        issuer={codeInfo.issuer}
                        account={codeInfo.account}
                        code={code}
                        nextCode={nextCode}
                    />
                    <Snackbar
                        open={hasCopied}
                        message="Code copied to clipboard"
                    />
                </ButtonBase>
            ) : (
                <BadCodeInfo codeInfo={codeInfo} codeErr={codeErr} />
            )}
        </div>
    );
};

interface TimerProgressProps {
    period: number;
}

const TimerProgress: React.FC<TimerProgressProps> = ({ period }) => {
    const [progress, setProgress] = useState(0);
    const [ticker, setTicker] = useState(null);
    const microSecondsInPeriod = period * 1000000;

    const startTicker = () => {
        const ticker = setInterval(() => {
            updateTimeRemaining();
        }, 10);
        setTicker(ticker);
    };

    const updateTimeRemaining = () => {
        const timeRemaining =
            microSecondsInPeriod -
            ((new Date().getTime() * 1000) % microSecondsInPeriod);
        setProgress(timeRemaining / microSecondsInPeriod);
    };

    useEffect(() => {
        startTicker();
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
