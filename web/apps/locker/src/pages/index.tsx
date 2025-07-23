import { Stack, Typography } from "@mui/material";
import { EnteLogo } from "ente-base/components/EnteLogo";
import React from "react";

const Page: React.FC = () => {
    return (
        <Stack
            sx={{
                justifyContent: "center",
                minHeight: "100vh",
                gap: 2,
                bgcolor: "accent.main",
                color: "white",
                textAlign: "center",
            }}
        >
            <EnteLogo height={42} />
            <Typography variant="h1" sx={{ fontWeight: "bold" }}>
                Locker
            </Typography>
            <Typography variant="small">— Coming soon —</Typography>
        </Stack>
    );
};

export default Page;
