import { styled } from "@mui/material";
import React from "react";

interface EnteLogoProps {
    /**
     * The height of the logo image.
     *
     * Default: 18
     */
    height?: number;
}

export const EnteLogo: React.FC<EnteLogoProps> = ({ height }) => (
    <LogoImage height={height ?? 18} alt="logo" src="/images/ente.svg" />
);

const LogoImage = styled("img")`
    margin: 3px 0;
    pointer-events: none;
    vertical-align: middle;
`;
