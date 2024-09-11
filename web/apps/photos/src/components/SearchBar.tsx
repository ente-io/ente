import { assertionFailed } from "@/base/assert";
import { useIsMobileWidth } from "@/base/hooks";
import { FileType } from "@/media/file-type";
import {
    isMLSupported,
    mlStatusSnapshot,
    mlStatusSubscribe,
} from "@/new/photos/services/ml";
import type {
    City,
    SearchDateComponents,
    SearchPerson,
    SearchResultSummary,
} from "@/new/photos/services/search/types";
import {
    ClipSearchScores,
    SearchOption,
    SearchQuery,
    SuggestionType,
} from "@/new/photos/services/search/types";
import { labelForSuggestionType } from "@/new/photos/services/search/ui";
import type { LocationTag } from "@/new/photos/services/user-entity";
import { EnteFile } from "@/new/photos/types/file";
import {
    FreeFlowText,
    SpaceBetweenFlex,
} from "@ente/shared/components/Container";
import CalendarIcon from "@mui/icons-material/CalendarMonth";
import CloseIcon from "@mui/icons-material/Close";
import FolderIcon from "@mui/icons-material/Folder";
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
import CollectionCard from "components/Collections/CollectionCard";
import { ResultPreviewTile } from "components/Collections/styledComponents";
import { t } from "i18next";
import pDebounce from "p-debounce";
import { AppContext } from "pages/_app";
import {
    useCallback,
    useContext,
    useEffect,
    useMemo,
    useRef,
    useState,
    useSyncExternalStore,
} from "react";
import {
    components as SelectComponents,
    type ControlProps,
    type InputActionMeta,
    type InputProps,
    type OptionProps,
    type StylesConfig,
} from "react-select";
import AsyncSelect from "react-select/async";
import { getAutoCompleteSuggestions } from "services/searchService";
import { type Collection } from "types/collection";

interface SearchBarProps {
    isInSearchMode: boolean;
    setIsInSearchMode: (v: boolean) => void;
    updateSearch: UpdateSearch;
    collections: Collection[];
    files: EnteFile[];
}

export type UpdateSearch = (
    search: SearchQuery,
    summary: SearchResultSummary,
) => void;

export const SearchBar: React.FC<SearchBarProps> = ({
    setIsInSearchMode,
    isInSearchMode,
    ...props
}) => {
    const isMobileWidth = useIsMobileWidth();

    const showSearchInput = () => setIsInSearchMode(true);

    return (
        <Box sx={{ flex: 1, px: ["4px", "24px"] }}>
            {isMobileWidth && !isInSearchMode ? (
                <MobileSearchArea onSearch={showSearchInput} />
            ) : (
                <SearchInput
                    {...props}
                    isOpen={isInSearchMode}
                    setIsOpen={setIsInSearchMode}
                />
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

interface SearchInputProps {
    isOpen: boolean;
    setIsOpen: (value: boolean) => void;
    updateSearch: UpdateSearch;
    files: EnteFile[];
    collections: Collection[];
}

const SearchInput: React.FC<SearchInputProps> = ({
    isOpen,
    setIsOpen,
    updateSearch,
    files,
    collections,
}) => {
    const appContext = useContext(AppContext);

    // A ref to the top level Select.
    const selectRef = useRef(null);
    // The currently selected option.
    const [value, setValue] = useState<SearchOption | undefined>();
    // The contents of the input field associated with the select.
    const [inputValue, setInputValue] = useState("");

    const theme = useTheme();

    const styles = useMemo(() => useSelectStyles(theme), [theme]);

    useEffect(() => {
        search(value);
    }, [value]);

    const handleChange = (value: SearchOption) => {
        setValue(value);
        setInputValue(value?.label);
        // The Select has a blurInputOnSelect prop, but that makes the input
        // field lose focus, not the entire menu (e.g. when pressing twice).
        //
        // We anyways need the ref so that we can blur on selecting a person
        // from the default options.
        selectRef.current?.blur();
    };

    const handleInputChange = (value: string, actionMeta: InputActionMeta) => {
        if (actionMeta.action === "input-change") {
            setInputValue(value);
        }
    };

    const resetSearch = () => {
        if (isOpen) {
            appContext.startLoading();
            updateSearch(null, null);
            setTimeout(() => {
                appContext.finishLoading();
            }, 10);
            setIsOpen(false);
            setValue(null);
            setInputValue("");
        }
    };

    const getOptions = useCallback(
        pDebounce(getAutoCompleteSuggestions(files, collections), 250),
        [files, collections],
    );

    const search = (selectedOption: SearchOption) => {
        if (!selectedOption) {
            return;
        }
        let search: SearchQuery;
        switch (selectedOption.type) {
            case SuggestionType.DATE:
                search = {
                    date: selectedOption.value as SearchDateComponents,
                };
                setIsOpen(true);
                break;
            case SuggestionType.LOCATION:
                search = {
                    location: selectedOption.value as LocationTag,
                };
                setIsOpen(true);
                break;
            case SuggestionType.CITY:
                search = {
                    city: selectedOption.value as City,
                };
                setIsOpen(true);
                break;
            case SuggestionType.COLLECTION:
                search = { collection: selectedOption.value as number };
                setValue(null);
                setInputValue("");
                break;
            case SuggestionType.FILE_NAME:
                search = { files: selectedOption.value as number[] };
                break;
            case SuggestionType.FILE_CAPTION:
                search = { files: selectedOption.value as number[] };
                break;
            case SuggestionType.PERSON:
                search = { person: selectedOption.value as SearchPerson };
                break;
            case SuggestionType.FILE_TYPE:
                search = { fileType: selectedOption.value as FileType };
                break;
            case SuggestionType.CLIP:
                search = { clip: selectedOption.value as ClipSearchScores };
        }
        updateSearch(search, {
            optionName: selectedOption.label,
            fileCount: selectedOption.fileCount,
        });
    };

    const handleSelectCGroup = (value: SearchOption) => {
        // Dismiss the search menu.
        selectRef.current?.blur();
        setValue(value);
    };

    const components = useMemo(() => ({ Option, Control, Input }), []);

    return (
        <SearchInputWrapper>
            <AsyncSelect
                ref={selectRef}
                value={value}
                components={components}
                styles={styles}
                placeholder={t("search_hint")}
                loadOptions={getOptions}
                onChange={handleChange}
                isMulti={false}
                isClearable
                escapeClearsValue
                inputValue={inputValue}
                onInputChange={handleInputChange}
                noOptionsMessage={({ inputValue }) =>
                    shouldShowEmptyState(inputValue) ? (
                        <EmptyState onSelectCGroup={handleSelectCGroup} />
                    ) : null
                }
            />

            {isOpen && (
                <IconButton onClick={() => resetSearch()} sx={{ ml: 1 }}>
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
    background: ${({ theme }) => theme.colors.background.base};
    max-width: 484px;
    margin: auto;
`;

const useSelectStyles = ({
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
        "& .main": {
            backgroundColor: isFocused && colors.background.elevated2,
        },
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
                {iconForOptionType(props.getValue()[0]?.type)}
            </Box>
            {children}
        </Stack>
    </SelectComponents.Control>
);

const iconForOptionType = (type: SuggestionType | undefined) => {
    switch (type) {
        case SuggestionType.DATE:
            return <CalendarIcon />;
        case SuggestionType.LOCATION:
        case SuggestionType.CITY:
            return <LocationIcon />;
        case SuggestionType.COLLECTION:
            return <FolderIcon />;
        case SuggestionType.FILE_NAME:
            return <ImageIcon />;
        default:
            return <SearchIcon />;
    }
};

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

    const status = isMLSupported && mlStatusSnapshot();
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
        <LabelWithInfo data={props.data} />
    </SelectComponents.Option>
);

const LabelWithInfo = ({ data }: { data: SearchOption }) => {
    return (
        <>
            <Box className="main" px={2} py={1}>
                <Typography variant="mini" mb={1}>
                    {labelForSuggestionType(data.type)}
                </Typography>
                <SpaceBetweenFlex>
                    <Box mr={1}>
                        <FreeFlowText>
                            <Typography fontWeight={"bold"}>
                                {data.label}
                            </Typography>
                        </FreeFlowText>
                        <Typography color="text.muted">
                            {t("photos_count", { count: data.fileCount })}
                        </Typography>
                    </Box>

                    <Stack direction={"row"} spacing={1}>
                        {data.previewFiles.map((file) => (
                            <CollectionCard
                                key={file.id}
                                coverFile={file}
                                onClick={() => null}
                                collectionTile={ResultPreviewTile}
                            />
                        ))}
                    </Stack>
                </SpaceBetweenFlex>
            </Box>
            <Divider sx={{ mx: 2, my: 1 }} />
        </>
    );
};

// A custom input for react-select that is always visible. This is a roundabout
// hack the existing code used to display the search string when showing the
// results page; likely there should be a better way.
const Input: React.FC<InputProps<SearchOption, false>> = (props) => (
    <SelectComponents.Input {...props} isHidden={false} />
);
