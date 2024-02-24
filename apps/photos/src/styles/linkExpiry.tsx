import { DropdownStyle } from "./dropdown";

export const linkExpiryStyle = {
    ...DropdownStyle,
    placeholder: (style) => ({
        ...style,
        color: "#d1d1d1",
        width: "100%",
        textAlign: "center",
    }),
};
