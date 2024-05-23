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
import { Button, TextField } from "@mui/material";
import OTPDisplay from "components/OTPDisplay";
import { t } from "i18next";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import React, { useContext, useEffect, useState } from "react";
import { getAuthCodes } from "services";

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
