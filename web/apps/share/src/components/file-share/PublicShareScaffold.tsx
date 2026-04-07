import { Box } from "@mui/material";
import Head from "next/head";
import React, { type ReactNode } from "react";

interface PublicShareScaffoldProps {
    children: ReactNode;
}

export const PublicShareScaffold: React.FC<PublicShareScaffoldProps> = ({
    children,
}) => {
    return (
        <>
            <Head>
                <meta name="robots" content="noindex, nofollow" />
            </Head>
            <Box
                sx={{
                    minHeight: "100dvh",
                    bgcolor: "#08090A",
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    boxSizing: "border-box",
                    "& ::selection": {
                        backgroundColor: "#1071FF",
                        color: "#FFFFFF",
                    },
                    "& ::-moz-selection": {
                        backgroundColor: "#1071FF",
                        color: "#FFFFFF",
                    },
                }}
            >
                <Box
                    sx={{
                        width: "100%",
                        background:
                            "linear-gradient(135deg, #1071FF 0%, #0056CC 100%)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        px: { xs: 2, sm: 3 },
                        pt: 2,
                        pb: 2.5,
                    }}
                >
                    <a
                        href="https://ente.com/locker"
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{ display: "block", lineHeight: 0 }}
                    >
                        <Box
                            component="img"
                            src="/images/ente-locker-white.svg"
                            alt="Ente Locker"
                            sx={{ height: { xs: "30px", md: "34px" } }}
                        />
                    </a>
                </Box>
                <Box
                    sx={{
                        width: "100%",
                        flex: 1,
                        display: "flex",
                        flexDirection: "column",
                        bgcolor: "#08090A",
                    }}
                >
                    {children}
                </Box>
            </Box>
        </>
    );
};
