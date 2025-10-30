import { Stack, Typography } from "@mui/material";
import React from "react";

const Page: React.FC = () => {
    return (
        <Stack
            sx={{
                justifyContent: "center",
                minHeight: "100vh",
                gap: 2,
                bgcolor: "white",
                textAlign: "center",
            }}
        >
            <img
                src="/images/ente-locker.svg"
                alt="Ente Locker"
                style={{ height: "100px", alignSelf: "center" }}
            />
            <Typography variant="small" sx={{ color: "#a2a2a2", mt: 4 }}>
                — Coming soon —
            </Typography>
        </Stack>
    );
};

export default Page;
