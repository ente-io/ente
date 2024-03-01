export const SelectStyles = {
    container: (style) => ({
        ...style,
        flex: 1,
    }),
    control: (style, { isFocused }) => ({
        ...style,
        backgroundColor: "rgba(255, 255, 255, 0.1)",

        borderColor: isFocused ? "#1dba54" : "transparent",
        boxShadow: "none",
        ":hover": {
            borderColor: "#1dba54",
            cursor: "text",
        },
    }),
    input: (style) => ({
        ...style,
        color: "#fff",
    }),
    menu: (style) => ({
        ...style,
        marginTop: "1px",
        backgroundColor: "#1b1b1b",
    }),
    option: (style, { isFocused }) => ({
        ...style,
        padding: 0,
        backgroundColor: "transparent !important",
        "& :hover": {
            cursor: "pointer",
        },
        "& .main": {
            backgroundColor: isFocused && "#202020",
        },
        "&:last-child .MuiDivider-root": {
            display: "none",
        },
    }),
    dropdownIndicator: (style) => ({
        ...style,
        display: "none",
    }),
    indicatorSeparator: (style) => ({
        ...style,
        display: "none",
    }),
    clearIndicator: (style) => ({
        ...style,
        display: "none",
    }),
    singleValue: (style) => ({
        ...style,
        backgroundColor: "transparent",
        color: "#d1d1d1",
        marginLeft: "36px",
    }),
    placeholder: (style) => ({
        ...style,
        color: "rgba(255, 255, 255, 0.7)",
        wordSpacing: "2px",
        whiteSpace: "nowrap",
        marginLeft: "40px",
    }),
};
