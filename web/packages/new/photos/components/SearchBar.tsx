import CalendarIcon from "@mui/icons-material/CalendarMonth";
import CloseIcon from "@mui/icons-material/Close";
import ImageIcon from "@mui/icons-material/Image";
import LocationIcon from "@mui/icons-material/LocationOn";
import SearchIcon from "@mui/icons-material/Search";
import {
    Box,
    Divider,
    IconButton,
    Stack,
    styled,
    Typography,
    useTheme,
    type Theme,
} from "@mui/material";
import { EnteLogo, EnteLogoBox } from "ente-base/components/EnteLogo";
import type { ButtonishProps } from "ente-base/components/mui";
import { useIsSmallWidth } from "ente-base/components/utils/hooks";
import {
    hlsGenerationStatusSnapshot,
    isHLSGenerationSupported,
} from "ente-gallery/services/video";
import { ItemCard, PreviewItemTile } from "ente-new/photos/components/Tiles";
import { isMLSupported, mlStatusSnapshot } from "ente-new/photos/services/ml";
import { searchOptionsForString } from "ente-new/photos/services/search";
import type { SearchOption } from "ente-new/photos/services/search/types";
import { nullToUndefined } from "ente-utils/transform";
import { t } from "i18next";
import pDebounce from "p-debounce";
import React, { useMemo, useRef, useState } from "react";
import {
    components as SelectComponents,
    type ControlProps,
    type InputActionMeta,
    type InputProps,
    type OptionProps,
    type SelectInstance,
    type StylesConfig,
} from "react-select";
import AsyncSelect from "react-select/async";
import { SearchPeopleList } from "./PeopleList";
import { UnstyledButton } from "./UnstyledButton";
import {
    useHLSGenerationStatusSnapshot,
    useMLStatusSnapshot,
    usePeopleStateSnapshot,
} from "./utils/use-snapshot";

export interface SearchBarProps {
    /**
     * [Note: "Search mode"]
     *
     * On mobile sized screens, normally the search input areas is not
     * displayed. Clicking the search icon enters the "search mode", where we
     * show the search input area.
     *
     * On other screens, the search input is always shown even if we are not in
     * search mode.
     *
     * When we're in search mode,
     *
     * 1. Other icons from the navbar are hidden.
     * 2. Next to the search input there is a cancel button to exit search mode.
     */
    isInSearchMode: boolean;
    /**
     * Invoked when the user wants to enter "search mode".
     *
     * This scenario only arises when the search bar is in the mobile device
     * sized configuration, where the user needs to tap the search icon to enter
     * the search mode.
     */
    onShowSearchInput: () => void;
    /**
     * Set or clear the selected {@link SearchOption}.
     */
    onSelectSearchOption: (o: SearchOption | undefined) => void;
    /**
     * Called when the user selects the generic "People" header in the empty
     * state view.
     */
    onSelectPeople: () => void;
    /**
     * Called when the user selects a person shown in the empty state view.
     */
    onSelectPerson: (personID: string) => void;
}

/**
 * The search bar is a styled "select" element that allow the user to type in
 * the attached input field, and shows a list of matching suggestions in a
 * dropdown.
 *
 * When the search input is empty, it shows some general information in the
 * dropdown instead (e.g. the ML indexing status).
 *
 * When the search input is not empty, it shows these {@link SearchSuggestion}s.
 * Alongside each suggestion is shows a count of matching files, and some
 * previews.
 *
 * Selecting one of the these suggestions causes the gallery to shows a filtered
 * list of files that match that suggestion.
 */
export const SearchBar: React.FC<SearchBarProps> = ({
    isInSearchMode,
    onShowSearchInput,
    ...rest
}) => {
    const isSmallWidth = useIsSmallWidth();

    return (
        <Box sx={{ flex: 1, px: ["4px", "24px"] }}>
            {isSmallWidth && !isInSearchMode ? (
                <MobileSearchArea onSearch={onShowSearchInput} />
            ) : (
                <SearchInput {...{ isInSearchMode }} {...rest} />
            )}
        </Box>
    );
};

interface MobileSearchAreaProps {
    /** Called when the user presses the search button. */
    onSearch: () => void;
}

const MobileSearchArea: React.FC<MobileSearchAreaProps> = ({ onSearch }) => (
    <Stack direction="row" sx={{ alignItems: "center" }}>
        <EnteLogoBox
            sx={{
                // Move to the center.
                mx: "auto",
                // Offset on the left by the visual size of the search icon to
                // make it look visually centered.
                pl: "24px",
            }}
        >
            <EnteLogo height={15} />
        </EnteLogoBox>
        <IconButton onClick={onSearch}>
            <SearchIcon />
        </IconButton>
    </Stack>
);

const SearchInput: React.FC<Omit<SearchBarProps, "onShowSearchInput">> = ({
    isInSearchMode,
    onSelectSearchOption,
    onSelectPeople,
    onSelectPerson,
}) => {
    // A ref to the top level Select.
    const selectRef = useRef<SelectInstance<SearchOption> | null>(null);
    // The currently selected option.
    //
    // We need to use `null` instead of `undefined` to indicate missing values,
    // because using `undefined` instead moves the Select from being a controlled
    // component to an uncontrolled component.
    const [value, setValue] = useState<SearchOption | null>(null);
    // The contents of the input field associated with the select.
    const [inputValue, setInputValue] = useState("");

    const theme = useTheme();

    const styles = useMemo(() => createSelectStyles(theme), [theme]);
    const components = useMemo(() => ({ Control, Input, Option }), []);

    const handleChange = (value: SearchOption | null) => {
        const type = value?.suggestion.type;
        // Collection and people suggestions are handled differently - our
        // caller will switch to the corresponding view, dismissing search.
        if (type == "collection" || type == "person") {
            setValue(null);
            setInputValue("");
        } else {
            setValue(value);
            setInputValue(value?.suggestion.label ?? "");
        }

        // Let our parent know the selection was changed.
        onSelectSearchOption(nullToUndefined(value));

        // The Select has a blurInputOnSelect prop, but that makes the input
        // field lose focus, not the entire menu (e.g. when pressing twice).
        //
        // We anyways need the ref so that we can blur on selecting a person
        // from the default options. So also use it to blur the entire Select
        // (including the menu) when the user selects an option.
        selectRef.current?.blur();
    };

    const handleInputChange = (value: string, actionMeta: InputActionMeta) => {
        if (actionMeta.action == "input-change") setInputValue(value);
    };

    const resetSearch = () => {
        // Dismiss the search menu if it is open.
        selectRef.current?.blur();

        // Clear all our state.
        setValue(null);
        setInputValue("");

        // Let our parent know.
        onSelectSearchOption(undefined);
    };

    const handleSelectPeople = () => {
        resetSearch();
        onSelectPeople();
    };

    const handleSelectPerson = (personID: string) => {
        resetSearch();
        onSelectPerson(personID);
    };

    const handleFocus = () => {
        // A workaround to show the suggestions again for the current non-empty
        // search string if the user focuses back on the input field after
        // moving focus elsewhere.
        if (inputValue) {
            selectRef.current?.onInputChange(inputValue, {
                action: "set-value",
                prevInputValue: "",
            });
        }
    };

    return (
        <SearchInputWrapper>
            <AsyncSelect
                ref={selectRef}
                value={value}
                components={components}
                styles={styles}
                loadOptions={loadOptions}
                onChange={handleChange}
                inputValue={inputValue}
                onInputChange={handleInputChange}
                isClearable
                escapeClearsValue
                onFocus={handleFocus}
                placeholder={t("search_hint")}
                noOptionsMessage={({ inputValue }) =>
                    shouldShowEmptyState(inputValue) ? (
                        <EmptyState
                            onSelectPeople={handleSelectPeople}
                            onSelectPerson={handleSelectPerson}
                        />
                    ) : null
                }
            />

            {isInSearchMode && (
                <IconButton onClick={resetSearch}>
                    <CloseIcon />
                </IconButton>
            )}
        </SearchInputWrapper>
    );
};

const SearchInputWrapper = styled("div")`
    display: flex;
    width: 100%;
    align-items: center;
    justify-content: center;
    gap: 8px;
    background: transparent;
    max-width: 484px;
    margin: auto;
`;

const loadOptions = pDebounce(searchOptionsForString, 250);

const createSelectStyles = (
    theme: Theme,
): StylesConfig<SearchOption, false> => ({
    container: (style) => ({ ...style, flex: 1 }),
    control: (style, { isFocused }) => ({
        ...style,
        backgroundColor: theme.vars.palette.background.searchInput,
        borderColor: isFocused ? theme.vars.palette.accent.main : "transparent",
        boxShadow: "none",
        ":hover": {
            borderColor: theme.vars.palette.accent.light,
            cursor: "text",
        },
    }),
    input: (styles) => ({
        ...styles,
        color: theme.vars.palette.text.base,
        overflowX: "hidden",
    }),
    menu: (style) => ({
        ...style,
        // Suppress the default margin at the top.
        marginTop: "1px",
        // Give an opaque and elevated surface color to the menu to override the
        // default (transparent).
        backgroundColor: theme.vars.palette.background.elevatedPaper,
    }),
    option: (style, { isFocused }) => ({
        ...style,
        padding: 0,
        backgroundColor: "transparent !important",
        "& :hover": { cursor: "pointer" },
        // Elevate the focused option further.
        "& .option-contents": isFocused
            ? { backgroundColor: theme.vars.palette.fill.fainter }
            : {},
        "&:last-child .MuiDivider-root": { display: "none" },
    }),
    placeholder: (style) => ({
        ...style,
        color: theme.vars.palette.text.muted,
        whiteSpace: "nowrap",
        overflowX: "hidden",
    }),
    // Hide some things we don't need.
    dropdownIndicator: (style) => ({ ...style, display: "none" }),
    indicatorSeparator: (style) => ({ ...style, display: "none" }),
    clearIndicator: (style) => ({ ...style, display: "none" }),
});

const Control = ({ children, ...props }: ControlProps<SearchOption, false>) => (
    <SelectComponents.Control {...props}>
        <Stack
            direction="row"
            sx={{
                alignItems: "center",
                // Fill the entire control (the control uses display flex).
                flex: 1,
            }}
        >
            <Box
                sx={{
                    display: "inline-flex",
                    // Match the default padding of the ValueContainer to make
                    // the icon look properly spaced and aligned.
                    pl: "8px",
                    color: "stroke.muted",
                }}
            >
                {iconForOption(props.getValue()[0])}
            </Box>
            {children}
        </Stack>
    </SelectComponents.Control>
);

const iconForOption = (option: SearchOption | undefined) => {
    switch (option?.suggestion.type) {
        case "fileName":
            return <ImageIcon />;
        case "date":
            return <CalendarIcon />;
        case "location":
        case "city":
            return <LocationIcon />;
        default:
            return <SearchIcon />;
    }
};

/**
 * A custom input for react-select that is always visible.
 *
 * This is a workaround to allow the search string to be always displayed, and
 * editable, even after the user has moved focus away from it.
 */
const Input: React.FC<InputProps<SearchOption, false>> = (props) => (
    <SelectComponents.Input {...props} isHidden={false} />
);

/**
 * A preflight check for whether or not we should show the EmptyState.
 *
 * react-select seems to only suppress showing anything at all in the menu if we
 * return `null` from the function passed to `noOptionsMessage`. Returning
 * `false`, or returning `null` from the EmptyState itself doesn't work and
 * causes a empty div to be shown instead.
 */
const shouldShowEmptyState = (inputValue: string) => {
    // Don't show empty state if the user has entered search input.
    if (inputValue) return false;

    // Don't show empty state if there is no ML related information AND we're
    // not processing videos.

    if (!isMLSupported && !isHLSGenerationSupported) {
        // Neither of ML or HLS generation is supported on current client. This
        // is the code path for web.
        return false;
    }

    const mlStatus = mlStatusSnapshot();
    const vpStatus = hlsGenerationStatusSnapshot();
    if (
        (!mlStatus || mlStatus.phase == "disabled") &&
        (!vpStatus?.enabled || vpStatus.status != "processing")
    ) {
        // ML is either not supported or currently disabled AND video processing
        // is either not supported or currently not happening. Don't show the
        // empty state.
        return false;
    }

    // Show it otherwise.
    return true;
};

/**
 * The view shown in the menu area when the user has not typed anything in the
 * search box.
 */
const EmptyState: React.FC<
    Pick<SearchBarProps, "onSelectPeople" | "onSelectPerson">
> = ({ onSelectPeople, onSelectPerson }) => {
    const mlStatus = useMLStatusSnapshot();
    const people = usePeopleStateSnapshot()?.visiblePeople;
    const vpStatus = useHLSGenerationStatusSnapshot();

    let label: string | undefined;
    switch (mlStatus?.phase) {
        case undefined:
        case "disabled":
        case "done":
            // If ML is not running, see if video processing is.
            if (vpStatus?.enabled && vpStatus.status == "processing") {
                label = t("processing_videos_status");
            }
            break;
        case "scheduled":
            label = t("indexing_scheduled");
            break;
        case "indexing":
            label = t("indexing_photos");
            break;
        case "fetching":
            label = t("indexing_fetching");
            break;
        case "clustering":
            label = t("indexing_people");
            break;
    }

    // If ML is disabled and we're not video processing, then don't show the
    // empty state content.
    if ((!mlStatus || mlStatus.phase == "disabled") && !label) {
        return <></>;
    }

    return (
        <Box sx={{ textAlign: "left" }}>
            {people && people.length > 0 && (
                <>
                    <SearchPeopleHeader onClick={onSelectPeople} />
                    <SearchPeopleList {...{ people, onSelectPerson }} />
                </>
            )}
            {label && (
                <Typography variant="mini" sx={{ mt: "5px", mb: "4px" }}>
                    {label}
                </Typography>
            )}
        </Box>
    );
};

const SearchPeopleHeader: React.FC<ButtonishProps> = ({ onClick }) => (
    <UnstyledButton {...{ onClick }}>
        <Typography
            sx={{ color: "text.muted", ":hover": { color: "text.base" } }}
        >
            {t("people")}
        </Typography>
    </UnstyledButton>
);

const Option: React.FC<OptionProps<SearchOption, false>> = (props) => (
    <SelectComponents.Option {...props}>
        <OptionContents data={props.data} />
        <Divider sx={{ mx: 2, my: 1 }} />
    </SelectComponents.Option>
);

const OptionContents = ({ data: option }: { data: SearchOption }) => (
    <Stack className="option-contents" sx={{ gap: "4px", px: 2, py: 1 }}>
        <Typography variant="mini" sx={{ color: "text.muted" }}>
            {labelForOption(option)}
        </Typography>
        <Stack
            direction="row"
            sx={{
                gap: 1,
                alignItems: "center",
                justifyContent: "space-between",
            }}
        >
            <Box>
                <Typography
                    sx={{
                        color: "text.base",
                        fontWeight: "medium",
                        wordBreak: "break-word",
                    }}
                >
                    {option.suggestion.label}
                </Typography>
                <Typography sx={{ color: "text.muted" }}>
                    {t("photos_count", { count: option.fileCount })}
                </Typography>
            </Box>

            <Stack direction="row" sx={{ gap: 1 }}>
                {option.previewFiles.map((file) => (
                    <ItemCard
                        key={file.id}
                        coverFile={file}
                        TileComponent={PreviewItemTile}
                    />
                ))}
            </Stack>
        </Stack>
    </Stack>
);

const labelForOption = (option: SearchOption) => {
    switch (option.suggestion.type) {
        case "collection":
            return t("album");

        case "fileType":
            return t("file_type");

        case "fileName":
            return t("file_name");

        case "fileCaption":
            return t("description");

        case "date":
            return t("date");

        case "location":
            return t("location");

        case "city":
            return t("location");

        case "clip":
            return t("magic");

        case "person":
            return t("people");
    }
};
