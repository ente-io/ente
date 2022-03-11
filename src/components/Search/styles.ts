export const SelectStyles = {
    control: (style, { isFocused }) => ({
        ...style,
        backgroundColor: '#282828',
        color: '#d1d1d1',

        borderColor: isFocused ? '#51cd7c' : '#444',
        boxShadow: 'none',
        ':hover': {
            borderColor: '#51cd7c',
            cursor: 'text',
            '&>.icon': { color: '#51cd7c' },
        },
    }),
    input: (style) => ({
        ...style,
        color: '#d2d2d1',
    }),
    menu: (style) => ({
        ...style,
        marginTop: '1px',
        backgroundColor: '#282828',
    }),
    option: (style, { isFocused }) => ({
        ...style,
        backgroundColor: isFocused && '#343434',
    }),
    dropdownIndicator: (style) => ({
        ...style,
        display: 'none',
    }),
    indicatorSeparator: (style) => ({
        ...style,
        display: 'none',
    }),
    clearIndicator: (style) => ({
        ...style,
        display: 'none',
    }),
    singleValue: (style, state) => ({
        ...style,
        backgroundColor: '#282828',
        color: '#d1d1d1',
        display: state.selectProps.menuIsOpen ? 'none' : 'block',
    }),
    placeholder: (style) => ({
        ...style,
        color: '#686868',
        wordSpacing: '2px',
        whiteSpace: 'nowrap',
    }),
};
