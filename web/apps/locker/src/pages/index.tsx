import { Stack, Typography } from "@mui/material";
import { EnteLogo } from "ente-base/components/EnteLogo";
import React from "react";

const Page: React.FC = () => {
    return (
        <Stack sx={{ justifyContent: "center", gap: 2 }}>
            <EnteLogo height={45} />
            <Typography variant="h2">Coming soon</Typography>
        </Stack>
    );
};

export default Page;
