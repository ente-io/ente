import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import { Box, IconButton, Typography } from "@mui/material";
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
        <Box>
            <IconButton>
                <ArrowBackIcon />
            </IconButton>
            <Typography variant="h3">Duplicates</Typography>
        </Box>
    );
};
