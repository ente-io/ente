// TODO: Audit this file.
import { ArrowDown02Icon, ArrowUp02Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import AddIcon from "@mui/icons-material/Add";
import CloseIcon from "@mui/icons-material/Close";
import EditIcon from "@mui/icons-material/Edit";
import HideImageOutlinedIcon from "@mui/icons-material/HideImageOutlined";
import MoreHorizIcon from "@mui/icons-material/MoreHoriz";
import PushPinIcon from "@mui/icons-material/PushPin";
import PushPinOutlinedIcon from "@mui/icons-material/PushPinOutlined";
import SearchIcon from "@mui/icons-material/Search";
import SortIcon from "@mui/icons-material/Sort";
import {
    Box,
    Dialog,
    DialogContent,
    DialogTitle,
    Divider,
    IconButton,
    InputAdornment,
    MenuItem,
    Stack,
    TextField,
    Tooltip,
    Typography,
    styled,
    useMediaQuery,
    type IconButtonProps,
    type PaperProps,
} from "@mui/material";
import Menu, { type MenuProps } from "@mui/material/Menu";
import { FilledIconButton } from "ente-base/components/mui";
import { DialogCloseIconButton } from "ente-base/components/mui/DialogCloseIconButton";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "ente-base/components/OverflowMenu";
import { SingleInputDialog } from "ente-base/components/SingleInputDialog";
import { useBaseContext } from "ente-base/context";
import { SlideUpTransition } from "ente-new/photos/components/mui/SlideUpTransition";
import {
    ItemCard,
    LargeTileButton,
    LargeTileCreateNewButton,
    LargeTileTextOverlay,
} from "ente-new/photos/components/Tiles";
import { useWrapAsyncOperation } from "ente-new/photos/components/utils/use-wrap-async";
import {
    addCGroup,
    addClusterToCGroup,
    ignoreCluster,
    pinCGroup,
    renameCGroup,
    unpinCGroup,
} from "ente-new/photos/services/ml";
import type { FaceCluster } from "ente-new/photos/services/ml/cluster";
import type {
    CGroupPerson,
    ClusterPerson,
    Person,
} from "ente-new/photos/services/ml/people";
import { t } from "i18next";
import memoize from "memoize-one";
import React, { useEffect, useMemo, useRef, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import {
    FixedSizeList,
    areEqual,
    type ListChildComponentProps,
} from "react-window";

export type PeopleSortBy =
    | "count-desc"
    | "count-asc"
    | "name-asc"
    | "name-desc";

interface AllPeopleProps {
    open: boolean;
    onClose: () => void;
    people: Person[];
    onSelectPerson: (id: string) => void;
    peopleSortBy: PeopleSortBy;
    onChangePeopleSortBy: (by: PeopleSortBy) => void;
}

export const AllPeople: React.FC<AllPeopleProps> = ({
    open,
    onClose,
    people,
    onSelectPerson,
    peopleSortBy,
    onChangePeopleSortBy,
}) => {
    const fullScreen = useMediaQuery("(max-width: 428px)");
    const { showMiniDialog } = useBaseContext();
    const [searchTerm, setSearchTerm] = useState("");
    const [personToRename, setPersonToRename] = useState<CGroupPerson>();
    const [clusterToName, setClusterToName] = useState<ClusterPerson>();

    const handleExited = () => {
        setSearchTerm("");
    };

    const handleSelectPerson = (personID: string) => {
        onSelectPerson(personID);
        onClose();
    };

    const handleRenamePerson = async (name: string) => {
        if (!personToRename) return;
        await renameCGroup(personToRename.cgroup, name);
        setPersonToRename(undefined);
    };

    const handlePinPerson = useWrapAsyncOperation(
        async (person: CGroupPerson) =>
            person.isPinned
                ? unpinCGroup(person.cgroup)
                : pinCGroup(person.cgroup),
    );

    const handleIgnorePerson = (person: ClusterPerson) => {
        showMiniDialog({
            title: t("ignore_person_confirm"),
            message: t("ignore_person_confirm_message"),
            continue: {
                text: t("ignore"),
                color: "primary",
                action: () => ignoreCluster(person.cluster),
            },
        });
    };

    const sortedPeople = useMemo(
        () => [...people].sort(personComparator(peopleSortBy)),
        [people, peopleSortBy],
    );

    const filteredPeople = useMemo(() => {
        if (!searchTerm.trim()) {
            return sortedPeople;
        }

        const searchLower = searchTerm.toLowerCase();
        return sortedPeople.filter((person) =>
            person.name?.toLowerCase().includes(searchLower),
        );
    }, [searchTerm, sortedPeople]);

    return (
        <>
            <AllPeopleDialog
                {...{ open, onClose, fullScreen }}
                fullWidth
                slots={{ transition: SlideUpTransition }}
                slotProps={{ transition: { onExited: handleExited } }}
            >
                <Title
                    onClose={onClose}
                    peopleCount={filteredPeople.length}
                    totalCount={people.length}
                    searchTerm={searchTerm}
                    onSearchChange={setSearchTerm}
                    peopleSortBy={peopleSortBy}
                    onChangePeopleSortBy={onChangePeopleSortBy}
                />
                <Divider />
                <AllPeopleContent
                    people={filteredPeople}
                    hasSearchQuery={!!searchTerm.trim()}
                    onSelectPerson={handleSelectPerson}
                    onRenamePerson={setPersonToRename}
                    onPinPerson={handlePinPerson}
                    onAddName={setClusterToName}
                    onIgnorePerson={handleIgnorePerson}
                />
            </AllPeopleDialog>
            <SingleInputDialog
                open={!!personToRename}
                onClose={() => setPersonToRename(undefined)}
                title={t("rename_person")}
                label={t("name")}
                placeholder={t("enter_name")}
                autoComplete="name"
                initialValue={personToRename?.name ?? ""}
                submitButtonColor="primary"
                submitButtonTitle={t("rename")}
                onSubmit={handleRenamePerson}
            />
            <AddPersonDialog
                open={!!clusterToName}
                onClose={() => setClusterToName(undefined)}
                people={people}
                cluster={clusterToName?.cluster}
            />
        </>
    );
};

const Column3To2Breakpoint = 559;
const PeopleRowItemSize = 154;
const personCardShellClassName = "all-people-person-card";

const AllPeopleDialog = styled(Dialog)(({ theme }) => ({
    "& .MuiDialog-container": { justifyContent: "flex-end" },
    "& .MuiPaper-root": { maxWidth: "494px" },
    "& .MuiDialogTitle-root": { padding: theme.spacing(2) },
    "& .MuiDialogContent-root": { padding: theme.spacing(2) },
    [theme.breakpoints.down(Column3To2Breakpoint)]: {
        "& .MuiPaper-root": { width: "324px" },
        "& .MuiDialogContent-root": { padding: 6 },
    },
}));

type TitleProps = {
    peopleCount: number;
    totalCount: number;
    searchTerm: string;
    onSearchChange: (value: string) => void;
    peopleSortBy: PeopleSortBy;
    onChangePeopleSortBy: (by: PeopleSortBy) => void;
} & Pick<AllPeopleProps, "onClose">;

const Title: React.FC<TitleProps> = ({
    onClose,
    peopleCount,
    totalCount,
    searchTerm,
    onSearchChange,
    peopleSortBy,
    onChangePeopleSortBy,
}) => (
    <DialogTitle>
        <Stack sx={{ gap: 1.5 }}>
            <Stack direction="row" sx={{ gap: 1.5 }}>
                <Stack sx={{ flex: 1 }}>
                    <Box>
                        <Typography variant="h5">{t("people")}</Typography>
                        <Typography
                            variant="small"
                            sx={{ color: "text.muted", fontWeight: "regular" }}
                        >
                            {searchTerm
                                ? `${peopleCount} / ${totalCount} ${t("people")}`
                                : `${peopleCount} ${t("people")}`}
                        </Typography>
                    </Box>
                </Stack>
                <PeopleSortOptions
                    activeSortBy={peopleSortBy}
                    onChangeSortBy={onChangePeopleSortBy}
                    nestedInDialog
                />
                <FilledIconButton onClick={onClose}>
                    <CloseIcon />
                </FilledIconButton>
            </Stack>
            <SearchField value={searchTerm} onChange={onSearchChange} />
        </Stack>
    </DialogTitle>
);

interface SearchFieldProps {
    value: string;
    onChange: (value: string) => void;
}

const SearchField: React.FC<SearchFieldProps> = ({ value, onChange }) => {
    const inputRef = useRef<HTMLInputElement>(null);

    useEffect(() => {
        const timeout = window.setTimeout(() => {
            inputRef.current?.focus();
            inputRef.current?.select();
        }, 0);

        return () => window.clearTimeout(timeout);
    }, []);

    const handleClear = () => {
        onChange("");
        inputRef.current?.focus();
    };

    return (
        <TextField
            inputRef={inputRef}
            fullWidth
            size="small"
            placeholder={`${t("search")} ${t("people").toLowerCase()}...`}
            value={value}
            onChange={(e) => onChange(e.target.value)}
            autoFocus
            slotProps={{
                input: {
                    startAdornment: (
                        <InputAdornment position="start">
                            <SearchIcon />
                        </InputAdornment>
                    ),
                    endAdornment: value && (
                        <InputAdornment
                            position="end"
                            sx={{ marginRight: "0 !important" }}
                        >
                            <CloseIcon
                                fontSize="small"
                                onClick={handleClear}
                                sx={{
                                    color: "stroke.muted",
                                    cursor: "pointer",
                                    "&:hover": { color: "text.base" },
                                }}
                            />
                        </InputAdornment>
                    ),
                },
            }}
            sx={{
                "& .MuiOutlinedInput-root": {
                    backgroundColor: "background.searchInput",
                    borderColor: "transparent",
                    "&:hover": { borderColor: "accent.light" },
                    "&.Mui-focused": {
                        borderColor: "accent.main",
                        boxShadow: "none",
                    },
                },
                "& .MuiInputBase-input": {
                    color: "text.base",
                    paddingTop: "8.5px !important",
                    paddingBottom: "8.5px !important",
                },
                "& .MuiInputAdornment-root": {
                    color: "stroke.muted",
                    marginTop: "0 !important",
                    marginRight: "8px",
                },
                "& .MuiOutlinedInput-notchedOutline": {
                    borderColor: "transparent",
                },
                "& .MuiInputBase-input::placeholder": {
                    color: "text.muted",
                    opacity: 1,
                },
            }}
        />
    );
};

type PeopleSortCategory = "name" | "count";

const getPeopleSortCategory = (sortBy: PeopleSortBy): PeopleSortCategory =>
    sortBy.startsWith("name") ? "name" : "count";

const isPeopleSortAscending = (sortBy: PeopleSortBy) => sortBy.endsWith("asc");

const getPeopleSortBy = (
    category: PeopleSortCategory,
    ascending: boolean,
): PeopleSortBy => `${category}-${ascending ? "asc" : "desc"}` as PeopleSortBy;

interface PeopleSortOptionsProps {
    activeSortBy: PeopleSortBy;
    onChangeSortBy: (by: PeopleSortBy) => void;
    nestedInDialog?: boolean;
    transparentTriggerButtonBackground?: boolean;
}

const PeopleSortOptions: React.FC<PeopleSortOptionsProps> = ({
    activeSortBy,
    onChangeSortBy,
    nestedInDialog,
    transparentTriggerButtonBackground,
}) => {
    const [anchorEl, setAnchorEl] = useState<MenuProps["anchorEl"]>();
    const pendingSortByRef = useRef<PeopleSortBy | undefined>(undefined);
    const ariaID = "people-sort";

    const activeCategory = getPeopleSortCategory(activeSortBy);
    const activeAscending = isPeopleSortAscending(activeSortBy);

    const handleCategoryClick = (category: PeopleSortCategory) => {
        let nextSortBy: PeopleSortBy;
        if (category === activeCategory) {
            nextSortBy = getPeopleSortBy(category, !activeAscending);
        } else {
            nextSortBy = getPeopleSortBy(category, category === "name");
        }
        pendingSortByRef.current = nextSortBy;
        setAnchorEl(undefined);
    };

    const triggerButtonSxProps: IconButtonProps["sx"] = [
        transparentTriggerButtonBackground
            ? {}
            : { backgroundColor: "fill.faint" },
    ];

    const menuPaperSxProps: PaperProps["sx"] | undefined = nestedInDialog
        ? { backgroundColor: "background.paper2" }
        : undefined;

    return (
        <>
            <IconButton
                onClick={(event) => setAnchorEl(event.currentTarget)}
                aria-controls={anchorEl ? ariaID : undefined}
                aria-haspopup="true"
                aria-expanded={anchorEl ? "true" : undefined}
                sx={triggerButtonSxProps}
            >
                <SortIcon />
            </IconButton>
            <StyledMenu
                id={ariaID}
                {...(anchorEl && { anchorEl })}
                open={!!anchorEl}
                onClose={() => setAnchorEl(undefined)}
                slotProps={{
                    paper: menuPaperSxProps ? { sx: menuPaperSxProps } : {},
                    list: { disablePadding: true, "aria-labelledby": ariaID },
                    transition: {
                        onExited: () => {
                            const nextSortBy = pendingSortByRef.current;
                            if (nextSortBy) {
                                pendingSortByRef.current = undefined;
                                onChangeSortBy(nextSortBy);
                            }
                        },
                    },
                }}
                anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
                transformOrigin={{ vertical: "top", horizontal: "right" }}
            >
                <PeopleSortCategoryOption
                    category="name"
                    activeCategory={activeCategory}
                    activeAscending={activeAscending}
                    onClick={handleCategoryClick}
                    label={t("name")}
                    directionLabel={
                        activeAscending
                            ? t("sort_asc_indicator")
                            : t("sort_desc_indicator")
                    }
                />
                <PeopleSortCategoryOption
                    category="count"
                    activeCategory={activeCategory}
                    activeAscending={activeAscending}
                    onClick={handleCategoryClick}
                    label={t("photos")}
                />
            </StyledMenu>
        </>
    );
};

interface PeopleSortCategoryOptionProps {
    category: PeopleSortCategory;
    activeCategory: PeopleSortCategory;
    activeAscending: boolean;
    onClick: (category: PeopleSortCategory) => void;
    label: string;
    directionLabel?: string;
}

const PeopleSortCategoryOption: React.FC<PeopleSortCategoryOptionProps> = ({
    category,
    activeCategory,
    activeAscending,
    onClick,
    label,
    directionLabel,
}) => {
    const isSelected = category === activeCategory;
    const arrowIcon = activeAscending ? ArrowUp02Icon : ArrowDown02Icon;

    return (
        <StyledMenuItem onClick={() => onClick(category)}>
            <Stack direction="row" sx={{ alignItems: "center" }}>
                <Typography
                    sx={{
                        color: isSelected ? "text.primary" : "text.secondary",
                    }}
                >
                    {label}
                </Typography>
                {isSelected && (
                    <Stack
                        direction="row"
                        sx={{
                            alignItems: "center",
                            ml: 1,
                            gap: 0.75,
                            color: "text.muted",
                        }}
                    >
                        {directionLabel && <Typography>•</Typography>}
                        {directionLabel && (
                            <Typography sx={{ fontSize: "0.9rem" }}>
                                {directionLabel}
                            </Typography>
                        )}
                        <HugeiconsIcon
                            icon={arrowIcon}
                            size={19}
                            color="currentColor"
                        />
                    </Stack>
                )}
            </Stack>
        </StyledMenuItem>
    );
};

const StyledMenu = styled(Menu)(({ theme }) => ({
    "& .MuiPaper-root": {
        backgroundColor: theme.vars.palette.background.elevatedPaper,
        minWidth: 220,
        width: 220,
        borderRadius: 12,
        boxShadow: theme.vars.palette.boxShadow.menu,
        marginTop: 6,
    },
    "& .MuiList-root": { padding: theme.spacing(1) },
}));

const StyledMenuItem = styled(MenuItem)(({ theme }) => ({
    display: "flex",
    alignItems: "center",
    gap: 12,
    borderRadius: 10,
    "& + &": { marginTop: 4 },
    "&.Mui-selected": { backgroundColor: theme.vars.palette.fill.faint },
}));

interface AllPeopleContentProps {
    people: Person[];
    hasSearchQuery: boolean;
    onSelectPerson: (id: string) => void;
    onRenamePerson: (person: CGroupPerson) => void;
    onPinPerson: (person: CGroupPerson) => void | Promise<void>;
    onAddName: (person: ClusterPerson) => void;
    onIgnorePerson: (person: ClusterPerson) => void;
}

interface ItemData {
    personRows: Person[][];
    onSelectPerson: (id: string) => void;
    onRenamePerson: (person: CGroupPerson) => void;
    onPinPerson: (person: CGroupPerson) => void | Promise<void>;
    onAddName: (person: ClusterPerson) => void;
    onIgnorePerson: (person: ClusterPerson) => void;
}

const createItemData = memoize(
    (
        personRows: Person[][],
        onSelectPerson: (id: string) => void,
        onRenamePerson: (person: CGroupPerson) => void,
        onPinPerson: (person: CGroupPerson) => void | Promise<void>,
        onAddName: (person: ClusterPerson) => void,
        onIgnorePerson: (person: ClusterPerson) => void,
    ) => ({
        personRows,
        onSelectPerson,
        onRenamePerson,
        onPinPerson,
        onAddName,
        onIgnorePerson,
    }),
);

const PeopleRow = React.memo(
    ({ data, index, style }: ListChildComponentProps<ItemData>) => {
        const {
            personRows,
            onSelectPerson,
            onRenamePerson,
            onPinPerson,
            onAddName,
            onIgnorePerson,
        } = data;
        const peopleRow = personRows[index]!;

        return (
            <div style={style}>
                <Stack
                    direction="row"
                    sx={{ px: 2, pt: index === 0 ? "16px" : 0, gap: 0.5 }}
                >
                    {peopleRow.map((person) => (
                        <PersonCard
                            key={person.id}
                            person={person}
                            onSelectPerson={onSelectPerson}
                            onRenamePerson={onRenamePerson}
                            onPinPerson={onPinPerson}
                            onAddName={onAddName}
                            onIgnorePerson={onIgnorePerson}
                        />
                    ))}
                </Stack>
            </div>
        );
    },
    areEqual,
);

const AllPeopleContent: React.FC<AllPeopleContentProps> = ({
    people,
    hasSearchQuery,
    onSelectPerson,
    onRenamePerson,
    onPinPerson,
    onAddName,
    onIgnorePerson,
}) => {
    const isTwoColumn = useMediaQuery(`(width < ${Column3To2Breakpoint}px)`);
    const columns = isTwoColumn ? 2 : 3;

    const personRows = useMemo(() => {
        const rows: Person[][] = [];
        for (let index = 0; index < people.length; index += columns) {
            rows.push(people.slice(index, index + columns));
        }
        return rows;
    }, [people, columns]);

    const itemData = createItemData(
        personRows,
        onSelectPerson,
        onRenamePerson,
        onPinPerson,
        onAddName,
        onIgnorePerson,
    );

    if (hasSearchQuery && people.length === 0) {
        return (
            <DialogContent sx={{ height: "80svh" }}>
                <CenteredMessage>
                    <Typography color="text.muted">
                        {t("no_results")}
                    </Typography>
                </CenteredMessage>
            </DialogContent>
        );
    }

    return (
        <DialogContent sx={{ "&&": { padding: 0 }, height: "80svh" }}>
            <AutoSizer>
                {({ width, height }) => (
                    <FixedSizeList
                        {...{ width, height }}
                        itemCount={personRows.length}
                        itemSize={PeopleRowItemSize}
                        itemData={itemData}
                    >
                        {PeopleRow}
                    </FixedSizeList>
                )}
            </AutoSizer>
        </DialogContent>
    );
};

const CenteredMessage = styled(Box)({
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    height: "100%",
});

interface PersonCardProps {
    person: Person;
    onSelectPerson: (id: string) => void;
    onRenamePerson: (person: CGroupPerson) => void;
    onPinPerson: (person: CGroupPerson) => void | Promise<void>;
    onAddName: (person: ClusterPerson) => void;
    onIgnorePerson: (person: ClusterPerson) => void;
}

const PersonCard: React.FC<PersonCardProps> = ({
    person,
    onSelectPerson,
    onRenamePerson,
    onPinPerson,
    onAddName,
    onIgnorePerson,
}) => (
    <PersonCardShell className={personCardShellClassName}>
        <ItemCard
            TileComponent={LargeTileButton}
            coverFile={person.displayFaceFile}
            coverFaceID={person.displayFaceID}
            onClick={() => onSelectPerson(person.id)}
        >
            <LargeTileTextOverlay>
                <Tooltip title={person.name ?? t("unnamed_person")} arrow>
                    <Typography
                        variant={person.name ? "body" : "small"}
                        sx={{
                            maxWidth: "118px",
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                            display: "-webkit-box",
                            WebkitLineClamp: person.name ? 2 : 1,
                            WebkitBoxOrient: "vertical",
                            fontSize: person.name ? undefined : "0.8rem",
                        }}
                    >
                        {person.name ?? t("unnamed_person")}
                    </Typography>
                </Tooltip>
                <Typography variant="small" sx={{ opacity: 0.7 }}>
                    {t("photos_count", { count: person.fileIDs.length })}
                </Typography>
            </LargeTileTextOverlay>
            {person.isPinned && (
                <PinnedIconContainer>
                    <PushPinIcon sx={{ fontSize: 20, color: "white" }} />
                </PinnedIconContainer>
            )}
        </ItemCard>
        <PersonActionMenu
            person={person}
            onRenamePerson={onRenamePerson}
            onPinPerson={onPinPerson}
            onAddName={onAddName}
            onIgnorePerson={onIgnorePerson}
        />
    </PersonCardShell>
);

const PersonCardShell = styled("div")`
    position: relative;
`;

const PinnedIconContainer = styled(Box)`
    position: absolute;
    inset-inline-end: 8px;
    inset-block-end: 8px;
    display: flex;
`;

interface PersonActionMenuProps {
    person: Person;
    onRenamePerson: (person: CGroupPerson) => void;
    onPinPerson: (person: CGroupPerson) => void | Promise<void>;
    onAddName: (person: ClusterPerson) => void;
    onIgnorePerson: (person: ClusterPerson) => void;
}

const PersonActionMenu: React.FC<PersonActionMenuProps> = ({
    person,
    onRenamePerson,
    onPinPerson,
    onAddName,
    onIgnorePerson,
}) => (
    <ActionMenuContainer>
        <OverflowMenu
            ariaID={`person-modal-options-${person.id}`}
            triggerButtonIcon={<MoreHorizIcon sx={{ fontSize: 18 }} />}
            triggerButtonSxProps={{
                color: "white",
                minWidth: 24,
                minHeight: 24,
                padding: "2px",
                opacity: 0.9,
                "&:hover": { backgroundColor: "transparent", opacity: 1 },
            }}
            menuPaperSxProps={{ minWidth: 176, width: 176 }}
        >
            {person.type === "cgroup" ? (
                <>
                    <OverflowMenuOption
                        compact
                        startIcon={<EditIcon />}
                        onClick={() => onRenamePerson(person)}
                    >
                        {t("rename")}
                    </OverflowMenuOption>
                    {person.isPinned ? (
                        <OverflowMenuOption
                            compact
                            startIcon={<PushPinOutlinedIcon />}
                            onClick={() => void onPinPerson(person)}
                        >
                            {t("unpin_person")}
                        </OverflowMenuOption>
                    ) : (
                        <OverflowMenuOption
                            compact
                            startIcon={<PushPinIcon />}
                            onClick={() => void onPinPerson(person)}
                        >
                            {t("pin_person")}
                        </OverflowMenuOption>
                    )}
                </>
            ) : (
                <>
                    <OverflowMenuOption
                        compact
                        startIcon={<AddIcon />}
                        onClick={() => onAddName(person)}
                    >
                        {t("add_a_name")}
                    </OverflowMenuOption>
                    <OverflowMenuOption
                        compact
                        startIcon={<HideImageOutlinedIcon />}
                        onClick={() => onIgnorePerson(person)}
                    >
                        {t("ignore")}
                    </OverflowMenuOption>
                </>
            )}
        </OverflowMenu>
    </ActionMenuContainer>
);

const ActionMenuContainer = styled(Box)`
    position: absolute;
    inset-block-start: 8px;
    inset-inline-end: 8px;
    z-index: 1;
    opacity: 0;
    pointer-events: none;
    transition: opacity 120ms ease;

    .${personCardShellClassName}:hover &,
    .${personCardShellClassName}:focus-within & {
        opacity: 1;
        pointer-events: auto;
    }

    @media (hover: none) {
        opacity: 1;
        pointer-events: auto;
    }
`;

type AddPersonDialogProps = {
    open: boolean;
    onClose: () => void;
    people: Person[];
    cluster: FaceCluster | undefined;
};

const AddPersonDialog: React.FC<AddPersonDialogProps> = ({
    open,
    onClose,
    people,
    cluster,
}) => {
    const isFullScreen = useMediaQuery("(max-width: 490px)");
    const [openNameInput, setOpenNameInput] = useState(false);

    const cgroupPeople: CGroupPerson[] = people.filter(
        (person): person is CGroupPerson => person.type != "cluster",
    );

    useEffect(() => {
        if (!open) {
            setOpenNameInput(false);
            return;
        }
        if (!cgroupPeople.length) {
            setOpenNameInput(true);
        }
    }, [open, cgroupPeople.length]);

    const handleAddPerson = () => setOpenNameInput(true);

    const handleAddPersonBySelect = useWrapAsyncOperation(
        async (personID: string) => {
            if (!cluster) return;
            const person = cgroupPeople.find((p) => p.id == personID);
            if (!person) return;

            await addClusterToCGroup(person.cgroup, cluster);
            setOpenNameInput(false);
            onClose();
        },
    );

    const handleAddPersonWithName = async (name: string) => {
        if (!cluster) return;
        await addCGroup(name, cluster);
        setOpenNameInput(false);
        onClose();
    };

    return (
        <>
            <Dialog
                open={open && !openNameInput && cgroupPeople.length > 0}
                onClose={onClose}
                fullWidth
                fullScreen={isFullScreen}
                slotProps={{ paper: { sx: { maxWidth: "490px" } } }}
            >
                <DialogTitle_>
                    <Typography variant="h3">{t("add_name")}</Typography>
                    <DialogCloseIconButton {...{ onClose }} />
                </DialogTitle_>
                <DialogContent_>
                    <LargeTileCreateNewButton onClick={handleAddPerson}>
                        {t("new_person")}
                    </LargeTileCreateNewButton>
                    {cgroupPeople.map((person) => (
                        <PersonPickerCard
                            key={person.id}
                            person={person}
                            onPersonClick={handleAddPersonBySelect}
                        />
                    ))}
                </DialogContent_>
            </Dialog>

            <SingleInputDialog
                open={openNameInput}
                onClose={() => {
                    setOpenNameInput(false);
                    if (!cgroupPeople.length) {
                        onClose();
                    }
                }}
                title={t("new_person")}
                label={t("add_name")}
                placeholder={t("enter_name")}
                autoComplete="name"
                submitButtonColor="primary"
                submitButtonTitle={t("add")}
                onSubmit={handleAddPersonWithName}
            />
        </>
    );
};

const DialogTitle_ = styled(Box)({
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    padding: "10px 8px 6px 24px",
});

const DialogContent_ = styled(DialogContent)`
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
`;

interface PersonPickerCardProps {
    person: Person;
    onPersonClick: (personID: string) => void;
}

const PersonPickerCard: React.FC<PersonPickerCardProps> = ({
    person,
    onPersonClick,
}) => (
    <ItemCard
        TileComponent={LargeTileButton}
        coverFile={person.displayFaceFile}
        coverFaceID={person.displayFaceID}
        onClick={() => onPersonClick(person.id)}
    >
        <LargeTileTextOverlay>
            <Typography>{person.name ?? ""}</Typography>
        </LargeTileTextOverlay>
    </ItemCard>
);

const personComparator =
    (sortBy: PeopleSortBy) =>
    (a: Person, b: Person): number => {
        if (a.isPinned !== b.isPinned) {
            return a.isPinned ? -1 : 1;
        }

        const sectionRankDiff = personSectionRank(a) - personSectionRank(b);

        if (sortBy.startsWith("name")) {
            const aName = a.name?.trim();
            const bName = b.name?.trim();
            if (!!aName !== !!bName) {
                return aName ? -1 : 1;
            }
            if (aName && bName) {
                const cmp = aName.localeCompare(bName, undefined, {
                    sensitivity: "base",
                });
                if (cmp) {
                    return sortBy === "name-asc" ? cmp : -cmp;
                }
            }
            return b.fileIDs.length - a.fileIDs.length;
        }

        if (sectionRankDiff) {
            return sectionRankDiff;
        }

        const countDiff = a.fileIDs.length - b.fileIDs.length;
        if (countDiff) {
            return sortBy === "count-asc" ? countDiff : -countDiff;
        }

        const aName = a.name?.trim();
        const bName = b.name?.trim();
        if (!!aName !== !!bName) {
            return aName ? -1 : 1;
        }
        if (aName && bName) {
            return aName.localeCompare(bName, undefined, {
                sensitivity: "base",
            });
        }
        return 0;
    };

const personSectionRank = (person: Person) =>
    person.type === "cgroup" ? 0 : 1;
