import { assertionFailed } from "@/base/assert";
import { useIsMobileWidth } from "@/base/hooks";
import { ItemCard, ResultPreviewTile } from "@/new/photos/components/ItemCards";
import {
    isMLSupported,
    mlStatusSnapshot,
    mlStatusSubscribe,
} from "@/new/photos/services/ml";
import { searchOptionsForString } from "@/new/photos/services/search";
import type { SearchOption } from "@/new/photos/services/search/types";
import { nullToUndefined } from "@/utils/transform";
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
import { t } from "i18next";
import pDebounce from "p-debounce";
import React, { useMemo, useRef, useState, useSyncExternalStore } from "react";
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
     * Enter or exit "search mode".
     */
    setIsInSearchMode: (b: boolean) => void;
    /**
     * Set or clear the selected {@link SearchOption}.
     */
    onSelectSearchOption: (o: SearchOption | undefined) => void;
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
    setIsInSearchMode,
    isInSearchMode,
    onSelectSearchOption,
}) => {
    const isMobileWidth = useIsMobileWidth();

    const showSearchInput = () => setIsInSearchMode(true);

    return (
        <Box sx={{ flex: 1, px: ["4px", "24px"] }}>
            {isMobileWidth && !isInSearchMode ? (
                <MobileSearchArea onSearch={showSearchInput} />
            ) : (
                <SearchInput {...{ isInSearchMode, onSelectSearchOption }} />
            )}
        </Box>
    );
};

interface MobileSearchAreaProps {
    /** Called when the user presses the search button. */
    onSearch: () => void;
}

const MobileSearchArea: React.FC<MobileSearchAreaProps> = ({ onSearch }) => (
    <Box sx={{ display: "flex", justifyContent: "flex-end" }}>
        <IconButton onClick={onSearch}>
            <SearchIcon />
        </IconButton>
    </Box>
);

const SearchInput: React.FC<Omit<SearchBarProps, "setIsInSearchMode">> = ({
    isInSearchMode,
    onSelectSearchOption,
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
        // Collection suggestions are handled differently - our caller will
        // switch to the collection view, dismissing search.
        if (value?.suggestion.type == "collection") {
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
        setValue(null);
        setInputValue("");
        onSelectSearchOption(undefined);
    };

    const handleSelectCGroup = (value: SearchOption) => {
        // Dismiss the search menu.
        selectRef.current?.blur();
        setValue(value);
        onSelectSearchOption(undefined);
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
                        <EmptyState onSelectCGroup={handleSelectCGroup} />
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

const SearchInputWrapper = styled(Box)`
    display: flex;
    width: 100%;
    align-items: center;
    justify-content: center;
    gap: 8px;
    background: ${({ theme }) => theme.colors.background.base};
    max-width: 484px;
    margin: auto;
`;

const loadOptions = pDebounce(searchOptionsForString, 250);

const createSelectStyles = ({
    colors,
}: Theme): StylesConfig<SearchOption, false> => ({
    container: (style) => ({ ...style, flex: 1 }),
    control: (style, { isFocused }) => ({
        ...style,
        backgroundColor: colors.background.elevated,
        borderColor: isFocused ? colors.accent.A500 : "transparent",
        boxShadow: "none",
        ":hover": {
            borderColor: colors.accent.A300,
            cursor: "text",
        },
    }),
    input: (styles) => ({ ...styles, color: colors.text.base }),
    menu: (style) => ({
        ...style,
        // Suppress the default margin at the top.
        marginTop: "1px",
        backgroundColor: colors.background.elevated,
    }),
    option: (style, { isFocused }) => ({
        ...style,
        padding: 0,
        backgroundColor: "transparent !important",
        "& :hover": {
            cursor: "pointer",
        },
        "& .option-contents": isFocused
            ? { backgroundColor: colors.background.elevated2 }
            : {},
        "&:last-child .MuiDivider-root": {
            display: "none",
        },
    }),
    placeholder: (style) => ({
        ...style,
        color: colors.text.muted,
        whiteSpace: "nowrap",
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
                    color: (theme) => theme.colors.stroke.muted,
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

    // Don't show empty state if there is no ML related information.
    if (!isMLSupported) return false;

    const status = mlStatusSnapshot();
    if (!status || status.phase == "disabled") return false;

    // Show it otherwise.
    return true;
};

interface EmptyStateProps {
    /** Called when the user selects a cgroup shown in the empty state view. */
    onSelectCGroup: (value: SearchOption) => void;
}

/**
 * The view shown in the menu area when the user has not typed anything in the
 * search box.
 */
const EmptyState: React.FC<EmptyStateProps> = () => {
    const mlStatus = useSyncExternalStore(mlStatusSubscribe, mlStatusSnapshot);

    if (!mlStatus || mlStatus.phase == "disabled") {
        assertionFailed();
        return <></>;
    }

    let label: string;
    switch (mlStatus.phase) {
        case "scheduled":
            label = t("indexing_scheduled");
            break;
        case "indexing":
            label = t("indexing_photos", mlStatus);
            break;
        case "fetching":
            label = t("indexing_fetching", mlStatus);
            break;
        case "clustering":
            label = t("indexing_people", mlStatus);
            break;
        case "done":
            label = t("indexing_done", mlStatus);
            break;
    }

    return (
        <Box>
            <Typography variant="mini" sx={{ textAlign: "left" }}>
                {label}
            </Typography>
        </Box>
    );

    // TODO-Cluster
    // const options = props.selectProps.options as SearchOption[];
    // const peopleSuggestions = options.filter(
    //     (o) => o.type === SuggestionType.PERSON,
    // );
    // const people = peopleSuggestions.map((o) => o.value as SearchPerson);
    // return (
    //     <SelectComponents.Menu {...props}>
    //         <Box my={1}>
    //             {isMLEnabled() &&
    //                 indexStatus &&
    //                 (people && people.length > 0 ? (
    //                     <Box>
    //                         <Legend>{t("people")}</Legend>
    //                     </Box>
    //                 ) : (
    //                     <Box height={6} />
    //                 ))}
    //             {isMLEnabled() && indexStatus && (
    //                 <Box>
    //                     <Caption>{indexStatusSuggestion.label}</Caption>
    //                 </Box>
    //             )}
    //             {people && people.length > 0 && (
    //                 <Row> // "@ente/shared/components/Container"
    //                     <PeopleList // @/new/photos/components/PeopleList
    //                         people={people}
    //                         maxRows={2}
    //                         onSelect={(_, index) => {
    //                         }}
    //                     />
    //                 </Row>
    //             )}
    //         </Box>
    //         {props.children}
    //     </SelectComponents.Menu>
    // );
};

// TODO-Cluster
// const Legend = styled("span")`
//     font-size: 20px;
//     color: #ddd;
//     display: inline;
//     padding: 0px 12px;
// `;

/*
TODO: Cluster

export async function getAllPeopleSuggestion(): Promise<Array<Suggestion>> {
    try {
        const people = await getAllPeople(200);
        return people.map((person) => ({
            label: person.name,
            type: SuggestionType.PERSON,
            value: person,
            hide: true,
        }));
    } catch (e) {
        log.error("getAllPeopleSuggestion failed", e);
        return [];
    }
}

async function getAllPeople(limit: number = undefined) {
    return (await wipSearchPersons()).slice(0, limit);
    // TODO-Clustetr
    // if (done) return [];

    // done = true;
    // if (process.env.NEXT_PUBLIC_ENTE_WIP_CL_FETCH) {
    //     await syncCGroups();
    //     const people = await clusterGroups();
    //     log.debug(() => ["people", { people }]);
    // }

    // let people: Array<SearchPerson> = []; // await mlIDbStorage.getAllPeople();
    // people = await wipCluster();
    // // await mlPeopleStore.iterate<Person, void>((person) => {
    // //     people.push(person);
    // // });
    // people = people ?? [];
    // const result = people
    //     .sort((p1, p2) => p2.files.length - p1.files.length)
    //     .slice(0, limit);
    // // log.debug(() => ["getAllPeople", result]);

    // return result;
}
*/

const Option: React.FC<OptionProps<SearchOption, false>> = (props) => (
    <SelectComponents.Option {...props}>
        <OptionContents data={props.data} />
        <Divider sx={{ mx: 2, my: 1 }} />
    </SelectComponents.Option>
);

const OptionContents = ({ data: option }: { data: SearchOption }) => (
    <Stack className="option-contents" gap={1} px={2} py={1}>
        <Typography variant="mini">{labelForOption(option)}</Typography>
        <Stack
            direction="row"
            gap={1}
            sx={{ alignItems: "center", justifyContent: "space-between" }}
        >
            <Box>
                <Typography
                    sx={{ fontWeight: "bold", wordBreak: "break-word" }}
                >
                    {option.suggestion.label}
                </Typography>
                <Typography color="text.muted">
                    {t("photos_count", { count: option.fileCount })}
                </Typography>
            </Box>

            <Stack direction={"row"} gap={1}>
                {option.previewFiles.map((file) => (
                    <ItemCard
                        key={file.id}
                        coverFile={file}
                        TileComponent={ResultPreviewTile}
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

        case "cgroup":
            return t("person");
    }
};
