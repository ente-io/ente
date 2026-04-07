import { styled } from "@mui/material";
import React from "react";
import { enteWordmarkPaths, enteWordmarkViewBox } from "./ente-wordmark";

interface EnteLogoProps {
    /**
     * The height of the logo image, in pixels.
     *
     * Default: 18px
     */
    height?: number;
}

/**
 * The Ente wordmark, as an inline SVG.
 *
 * Having it as an inline SVG has two advantages:
 *
 * - It does not rely on a corresponding asset in the public folder
 * - It can be styled using CSS.
 *
 * The default height of the SVG element is 18px. The size can be customized by
 * providing a {@link height} prop: the SVG will preserve its aspect ratio when
 * fitting inside the provided viewport.
 */
export const EnteLogo: React.FC<EnteLogoProps> = ({ height }) => (
    <svg
        height={height ?? 18}
        viewBox={enteWordmarkViewBox}
        xmlns="http://www.w3.org/2000/svg"
    >
        {enteWordmarkPaths.map((d, index) => (
            <path key={index} d={d} fill="currentColor" />
        ))}
    </svg>
);

/**
 * A container for {@link EnteLogo} that resets the line height to vertically
 * center the logo within the surrounding context.
 *
 * By default, the line height causes the SVG to have an extra space at the
 * bottom. Removing it allows the SVG contents to be centered using its inherent
 * sizing. This is a convenience container that resets the line height, and also
 * takes the {@link sx} prop to allow for easy tweaking of other styling of the
 * container without touching the SVG.
 */
export const EnteLogoBox = styled("div")`
    line-height: 0;
`;
