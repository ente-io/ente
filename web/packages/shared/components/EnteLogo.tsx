import { styled } from "@mui/material";
import React from "react";

interface EnteLogoProps {
    /**
     * The height of the logo image, in pixels.
     *
     * Default: 18px
     */
    height?: number;
}

/**
 * The Ente logo ("ente" in Montserrat).
 *
 * This is meant as a standard img element that can be used in places where we
 * need to show the Ente branding. The img is backed by an an SVG.
 *
 * @see {@link EnteLogoSvg} for a variant but visually similar component that
 * uses an inline svg instead.
 *
 * The img has a default height of 18px, but can be customized using the
 * {@link height} prop.
 *
 * The img also has a 3px vertical margin on both sides.
 */
export const EnteLogo: React.FC<EnteLogoProps> = ({ height }) => (
    <LogoImage height={height ?? 18} alt="Ente" src="/images/ente.svg" />
);

const LogoImage = styled("img")`
    margin: 3px 0;
    pointer-events: none;
    vertical-align: middle;
`;
