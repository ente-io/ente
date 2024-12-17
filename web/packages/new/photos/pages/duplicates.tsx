import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import MoreHorizIcon from "@mui/icons-material/MoreHoriz";
import SortIcon from "@mui/icons-material/Sort";
import { Box, IconButton, Stack, Typography } from "@mui/material";
import React, { useEffect } from "react";
import { useAppContext } from "../types/context";

const Page: React.FC = () => {
    const { showNavBar } = useAppContext();

    useEffect(() => {
        showNavBar(true);
    }, []);
    return (
        <div>
            <Navbar />
            Hello
        </div>
    );
};

export default Page;

const Navbar: React.FC = () => {
    return (
        <Stack
            direction="row"
            sx={{ alignItems: "center", justifyContent: "space-between" }}
        >
            <Box sx={{ minWidth: "100px" /* 2 icons + gap */ }}>
                <IconButton>
                    <ArrowBackIcon />
                </IconButton>
            </Box>
            <Typography variant="large">Remove duplicates</Typography>
            <Stack direction="row" sx={{ gap: "4px" }}>
                <IconButton>
                    <SortIcon />
                </IconButton>
                <IconButton>
                    <MoreHorizIcon />
                </IconButton>
            </Stack>
        </Stack>
    );
};
