import { Dialog, styled, useMediaQuery } from "@mui/material";
import React from "react";

export const WhatsNew: React.FC = () => {
    const fullScreen = useMediaQuery("(max-width:428px)");

    return (
        <Dialog open={true} fullScreen={fullScreen}>
            <Contents>Hello</Contents>
        </Dialog>
    );
};

const Contents = styled("div")`
    width: 300px;
    height: 300px;
`;
