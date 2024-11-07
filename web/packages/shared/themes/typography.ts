import type { TypographyOptions } from "@mui/material/styles/createTypography";

export const typography: TypographyOptions = {
    h1: {
        fontSize: "48px",
        lineHeight: "58px",
    },
    h2: {
        fontSize: "32px",
        lineHeight: "39px",
    },
    h3: {
        fontSize: "24px",
        lineHeight: "29px",
    },
    h4: {
        fontSize: "22px",
        lineHeight: "27px",
    },
    h5: {
        fontSize: "20px",
        lineHeight: "25px",
        // Browser default is bold, but MUI resets it to 500 which is too light
        // for our chosen font.
        fontWeight: "bold",
    },
    // h6 is the default variant used by MUI's DialogTitle.
    h6: {
        // The font size and line height belows is the same as large.
        fontSize: "18px",
        lineHeight: "22px",
        // Browser default is bold, but MUI resets it to 500 which is too light
        // for our chosen font.
        fontWeight: "bold",
    },
    large: {
        fontSize: "18px",
        lineHeight: "22px",
    },
    body: {
        fontSize: "16px",
        lineHeight: "20px",
    },
    small: {
        fontSize: "14px",
        lineHeight: "17px",
    },
    mini: {
        fontSize: "12px",
        lineHeight: "15px",
    },
    tiny: {
        fontSize: "10px",
        lineHeight: "12px",
    },
    fontFamily: ["Inter", "sans-serif"].join(","),
};
