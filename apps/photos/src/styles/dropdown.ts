import { SelectStyles } from "./search";

export const DropdownStyle = {
    ...SelectStyles,
    dropdownIndicator: (style) => ({
        ...style,
        margin: "0px",
    }),
    singleValue: (style) => ({
        ...style,
        color: "#d1d1d1",
        width: "240px",
    }),
    control: (style, { isFocused }) => ({
        ...style,
        ...SelectStyles.control(style, { isFocused }),
        minWidth: "240px",
        paddingLeft: "8px",
    }),
};
