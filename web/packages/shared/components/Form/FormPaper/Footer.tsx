import { VerticallyCentered } from "@ente/shared/components/Container";
import { Divider, type BoxProps } from "@mui/material";
import React from "react";

const FormPaperFooter: React.FC<BoxProps> = ({ sx, style, ...props }) => {
    return (
        <>
            <Divider />
            <VerticallyCentered
                style={{ flexDirection: "row", ...style }}
                sx={{
                    mt: 3,
                    ...sx,
                }}
                {...props}
            >
                {props.children}
            </VerticallyCentered>
        </>
    );
};

export default FormPaperFooter;
