import { VerticallyCentered } from "@ente/shared/components/Container";
import { BoxProps, Divider } from "@mui/material";
import { FC } from "react";

const FormPaperFooter: FC<BoxProps> = ({ sx, style, ...props }) => {
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
