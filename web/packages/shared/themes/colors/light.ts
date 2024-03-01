import { FixedColors, ThemeColorsOptions } from "@mui/material";

const lightThemeColors: Omit<ThemeColorsOptions, keyof FixedColors> = {
    background: {
        base: "#fff",
        elevated: "#fff",
        elevated2: "rgba(153, 153, 153, 0.04)",
    },
    backdrop: {
        base: "rgba(255, 255, 255, 0.92)",
        muted: "rgba(255, 255, 255, 0.75)",
        faint: "rgba(255, 255, 255, 0.30)",
    },
    text: {
        base: "#000",
        muted: "rgba(0, 0, 0, 0.60)",
        faint: "rgba(0, 0, 0, 0.50)",
    },
    fill: {
        base: "#000",
        muted: "rgba(0, 0, 0, 0.12)",
        faint: "rgba(0, 0, 0, 0.04)",
        basePressed: "rgba(0, 0, 0, 0.87))",
        faintPressed: "rgba(0, 0, 0, 0.08)",
        strong: "rgba(0, 0, 0, 0.24)",
    },
    stroke: {
        base: "#000",
        muted: "rgba(0, 0, 0, 0.24)",
        faint: "rgba(0, 0, 0, 0.12)",
        fainter: "rgba(0, 0, 0, 0.06)",
    },

    shadows: {
        float: [{ x: 0, y: 0, blur: 10, color: "rgba(0, 0, 0, 0.25)" }],
        menu: [
            {
                x: 0,
                y: 0,
                blur: 6,
                color: "rgba(0, 0, 0, 0.16)",
            },
            {
                x: 0,
                y: 3,
                blur: 6,
                color: "rgba(0, 0, 0, 0.12)",
            },
        ],
        button: [
            {
                x: 0,
                y: 4,
                blur: 4,
                color: "rgba(0, 0, 0, 0.25)",
            },
        ],
    },
    avatarColors: [
        "#76549A",
        "#DF7861",
        "#94B49F",
        "#87A2FB",
        "#C689C6",
        "#937DC2",
        "#325288",
        "#85B4E0",
        "#C1A3A3",
        "#E1A059",
        "#426165",
        "#6B77B2",
        "#957FEF",
        "#DD9DE2",
        "#82AB8B",
        "#9BBBE8",
        "#8FBEBE",
        "#8AC3A1",
        "#A8B0F2",
        "#B0C695",
        "#E99AAD",
        "#D18484",
        "#78B5A7",
    ],
};

export default lightThemeColors;
