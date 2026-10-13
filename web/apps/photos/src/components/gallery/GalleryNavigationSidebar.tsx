import { AllAlbums } from "@/components/Collections/AllAlbums";
import { AllPeople } from "@/components/Collections/AllPeople";
import { CollectionsSortOptions } from "@/components/CollectionsSortOptions";
import { PeopleSortOptions } from "@/components/PeopleSortOptions";
import { sortPeople, type PeopleSortBy } from "@/utils/people-sort";
import { Link05Icon, StarIcon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import ArchiveIcon from "@mui/icons-material/Archive";
import CloseIcon from "@mui/icons-material/Close";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import PeopleIcon from "@mui/icons-material/People";
import PushPinIcon from "@mui/icons-material/PushPin";
import {
    Box,
    ButtonBase,
    Drawer,
    IconButton,
    Stack,
    Tooltip,
    Typography,
    styled,
    useMediaQuery,
    useTheme,
} from "@mui/material";
import {
    useModalVisibility,
    type ModalVisibilityProps,
} from "ente-base/components/utils/modal";
import type { EnteFile } from "ente-media/file";
import { ItemCard } from "ente-new/photos/components/Tiles";
import {
    PseudoCollectionID,
    collectionsSortBy as collectionSortOptions,
    haveOnlySystemCollections,
    sortCollectionSummaries,
    type CollectionSummaries,
    type CollectionSummaryAttribute,
    type CollectionsSortBy,
} from "ente-new/photos/services/collection-summary";
import type { Person } from "ente-new/photos/services/ml/people";
import { includes } from "ente-utils/type-guards";
import { t } from "i18next";
import React, {
    memo,
    useCallback,
    useEffect,
    useId,
    useMemo,
    useRef,
    useState,
    type ReactNode,
} from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import {
    FixedSizeList,
    areEqual,
    type ListChildComponentProps,
} from "react-window";
import type { RemotePullOpts } from ".";
import type { GalleryBarMode } from "./reducer";

export interface GalleryNavigationSidebarProps {
    mode: GalleryBarMode;
    shouldHide: boolean;
    collapsed: boolean;
    mobileDrawerProps: ModalVisibilityProps;
    collectionSummaries: CollectionSummaries;
    activeCollectionID: number | undefined;
    onSelectCollectionID: (id: number) => void;
    people: Person[];
    allPeople: Person[];
    activePerson: Person | undefined;
    onSelectPerson: (id: string) => void;
    canCreateAlbum: boolean;
    onRemotePull: (opts?: RemotePullOpts) => Promise<void>;
}

export const GalleryNavigationSidebar: React.FC<
    GalleryNavigationSidebarProps
> = ({
    mode,
    shouldHide,
    collapsed,
    mobileDrawerProps,
    collectionSummaries,
    activeCollectionID,
    onSelectCollectionID,
    people,
    allPeople,
    activePerson,
    onSelectPerson,
    canCreateAlbum,
    onRemotePull,
}) => {
    const mobile = useMediaQuery(useTheme().breakpoints.down("md"));
    const titleID = useId();
    const { onClose: closeMobileDrawer } = mobileDrawerProps;
    const { show: showAllAlbums, props: allAlbumsProps } = useModalVisibility();
    const { show: showAllPeople, props: allPeopleProps } = useModalVisibility();
    const [collectionsSortBy, setCollectionsSortBy] =
        useCollectionsSortByLocalState();
    const [peopleSortBy, setPeopleSortBy] =
        useState<PeopleSortBy>("count-desc");
    const sortedCollections = useMemo(
        () =>
            sortCollectionSummaries(
                [...collectionSummaries.values()],
                collectionsSortBy,
            ).sort((a, b) => b.sortPriority - a.sortPriority),
        [collectionSummaries, collectionsSortBy],
    );
    const sortedPeople = useMemo(
        () => sortPeople(people, peopleSortBy),
        [people, peopleSortBy],
    );
    const entries = useMemo<NavigationEntry[]>(
        () =>
            mode == "people"
                ? sortedPeople.map((person) => ({
                      id: person.id,
                      name: person.name ?? "",
                      coverFile: person.displayFaceFile,
                      faceID: person.displayFaceID,
                      badges: person.isPinned
                          ? [<PushPinIcon key="pin" sx={{ fontSize: 14 }} />]
                          : [],
                  }))
                : sortedCollections
                      .filter(
                          (cs) =>
                              !cs.attributes.has("hideFromCollectionBar") &&
                              !cs.attributes.has("quickLink") &&
                              (mode != "albums" ||
                                  !cs.attributes.has("archived")),
                      )
                      .map((cs) => ({
                          id: cs.id,
                          name: cs.name,
                          coverFile: cs.coverFile,
                          faceID: undefined,
                          badges: collectionBadges(cs.attributes),
                      })),
        [mode, sortedCollections, sortedPeople],
    );
    const onSelect = useCallback(
        (id: number | string) => {
            if (typeof id == "number") onSelectCollectionID(id);
            else onSelectPerson(id);
            closeMobileDrawer();
        },
        [onSelectCollectionID, onSelectPerson, closeMobileDrawer],
    );

    if (
        shouldHide ||
        (!mobile &&
            haveOnlySystemCollections(collectionSummaries) &&
            activeCollectionID === PseudoCollectionID.all)
    )
        return null;

    const title =
        mode == "people"
            ? t("people")
            : mode == "hidden-albums"
              ? t("hidden_albums")
              : mode == "archive-albums"
                ? t("section_archive")
                : t("albums");

    const navigation = (
        <Stack
            component="nav"
            aria-label={title}
            sx={(theme) => ({
                "--gallery-navigation-surface": "#FFFFFF",
                "--gallery-navigation-hover":
                    "color-mix(in srgb, var(--mui-palette-text-base) 8%, var(--gallery-navigation-surface))",
                display: collapsed && !mobile ? "none" : "flex",
                flexShrink: 0,
                width: mobile ? "100%" : 328,
                height: "100%",
                minHeight: 0,
                px: mobile ? "12px" : "16px",
                py: mobile ? "14px" : 0,
                borderLeft: mobile ? 0 : "1px solid",
                borderColor: "#E0E0E0",
                gap: "16px",
                ...theme.applyStyles("dark", {
                    "--gallery-navigation-surface": "#212121",
                    borderColor: "#3E3E3E",
                }),
            })}
        >
            <Stack
                direction="row"
                sx={{
                    alignItems: "center",
                    flexShrink: 0,
                    height: 38,
                    gap: 0.5,
                    "& .MuiIconButton-root": {
                        width: 38,
                        height: 38,
                        borderRadius: "12px",
                        bgcolor: "var(--gallery-navigation-surface)",
                        "&:hover": {
                            bgcolor: "var(--gallery-navigation-hover)",
                        },
                    },
                }}
            >
                <Typography
                    component="h2"
                    id={titleID}
                    sx={{
                        flex: 1,
                        minWidth: 0,
                        fontFamily: '"Outfit Variable", Outfit, sans-serif',
                        fontSize: mobile ? 20 : 24,
                        fontWeight: 600,
                        lineHeight: mobile ? "26px" : "32px",
                    }}
                >
                    {title}
                </Typography>
                {mode == "people" ? (
                    <PeopleSortOptions
                        variant="v2"
                        activeSortBy={peopleSortBy}
                        onChangeSortBy={setPeopleSortBy}
                    />
                ) : (
                    <CollectionsSortOptions
                        variant="v2"
                        activeSortBy={collectionsSortBy}
                        onChangeSortBy={setCollectionsSortBy}
                    />
                )}
                <Tooltip
                    title={mode == "people" ? t("people") : t("all_albums")}
                >
                    <IconButton
                        aria-label={
                            mode == "people" ? t("people") : t("all_albums")
                        }
                        aria-haspopup="dialog"
                        onClick={
                            mode == "people" ? showAllPeople : showAllAlbums
                        }
                    >
                        <ExpandMoreIcon sx={{ fontSize: 20 }} />
                    </IconButton>
                </Tooltip>
                {mobile && (
                    <IconButton
                        aria-label={t("close")}
                        onClick={closeMobileDrawer}
                    >
                        <CloseIcon sx={{ fontSize: 20 }} />
                    </IconButton>
                )}
            </Stack>
            <NavigationList
                key={mode}
                {...{ entries, collapsed, onSelect, mobile }}
                activeID={
                    mode == "people" ? activePerson?.id : activeCollectionID
                }
            />
        </Stack>
    );

    return (
        <>
            {mobile ? (
                <Drawer
                    {...mobileDrawerProps}
                    anchor="left"
                    slotProps={{
                        backdrop: { sx: { bgcolor: "rgba(0,0,0,0.4)" } },
                        paper: {
                            role: "dialog",
                            "aria-modal": true,
                            "aria-labelledby": titleID,
                            sx: (theme) => ({
                                width: "min(328px, 94vw)",
                                borderRadius: "0 20px 20px 0",
                                boxShadow: "0 24px 60px rgba(0,0,0,0.3)",
                                bgcolor: "#F4F4F4",
                                ...theme.applyStyles("dark", {
                                    bgcolor: "#161616",
                                }),
                            }),
                        },
                    }}
                >
                    {navigation}
                </Drawer>
            ) : (
                navigation
            )}
            <AllAlbums
                {...allAlbumsProps}
                collectionSummaries={sortedCollections.filter(
                    (cs) => !cs.attributes.has("system"),
                )}
                {...{ collectionsSortBy, canCreateAlbum, onRemotePull }}
                onSelectCollectionID={onSelect}
                onChangeCollectionsSortBy={setCollectionsSortBy}
                isInHiddenSection={mode == "hidden-albums"}
            />
            <AllPeople
                {...allPeopleProps}
                {...{ allPeople, peopleSortBy }}
                onSelectPerson={onSelect}
                people={sortedPeople}
                onChangePeopleSortBy={setPeopleSortBy}
            />
        </>
    );
};

interface NavigationEntry {
    id: number | string;
    name: string;
    coverFile: EnteFile | undefined;
    faceID: string | undefined;
    badges: ReactNode[];
}

interface NavigationListProps {
    entries: NavigationEntry[];
    mobile: boolean;
    collapsed: boolean;
    activeID: number | string | undefined;
    onSelect: (id: number | string) => void;
}

const NavigationList: React.FC<NavigationListProps> = ({
    entries,
    mobile,
    collapsed,
    activeID,
    onSelect,
}) => {
    const listRef = useRef<FixedSizeList>(null);
    const pendingFocus = useRef<number | string | undefined>(undefined);
    const [focusedID, setFocusedID] = useState<number | string>();
    const [viewportHeight, setViewportHeight] = useState(0);
    useEffect(() => setFocusedID(activeID), [activeID]);
    const activeIndex = entries.findIndex(({ id }) => id === activeID);
    useEffect(() => {
        if (activeIndex >= 0)
            listRef.current?.scrollToItem(activeIndex, "smart");
    }, [activeIndex, collapsed, viewportHeight, mobile]);

    const focusIndex = entries.findIndex(({ id }) => id === focusedID);
    const tabStopIndex =
        focusIndex >= 0 ? focusIndex : Math.max(0, activeIndex);
    const data = useMemo<RowData>(
        () => ({
            entries,
            mobile,
            activeID,
            onSelect,
            tabStopIndex,
            pendingFocus,
            onFocus: setFocusedID,
        }),
        [entries, mobile, activeID, onSelect, tabStopIndex],
    );

    return (
        <Box
            sx={{ flex: 1, minHeight: 0, minWidth: 0, position: "relative" }}
            onKeyDown={(event) => {
                const target = (
                    event.target as HTMLElement
                ).closest<HTMLElement>("[data-navigation-index]");
                if (!target) return;
                const index = Number(target.dataset.navigationIndex);
                let next: number;
                switch (event.key) {
                    case "Home":
                        next = 0;
                        break;
                    case "End":
                        next = entries.length - 1;
                        break;
                    case "ArrowDown":
                        next = Math.min(entries.length - 1, index + 1);
                        break;
                    case "ArrowUp":
                        next = Math.max(0, index - 1);
                        break;
                    default:
                        return;
                }
                event.preventDefault();
                const entry = entries[next];
                if (!entry) return;
                pendingFocus.current = entry.id;
                listRef.current?.scrollToItem(next, "smart");
                setFocusedID(entry.id);
            }}
        >
            <AutoSizer onResize={({ height }) => setViewportHeight(height)}>
                {({ width, height }) => (
                    <FixedSizeList
                        ref={listRef}
                        outerElementType={NavigationScrollContainer}
                        {...{ width, height }}
                        itemSize={mobile ? 46 : 50}
                        itemCount={entries.length}
                        itemData={data}
                        itemKey={(index, rowData: RowData) =>
                            rowData.entries[index]!.id
                        }
                        style={{ overflowX: "hidden" }}
                    >
                        {NavigationRow}
                    </FixedSizeList>
                )}
            </AutoSizer>
        </Box>
    );
};

const NavigationScrollContainer = styled("div")({
    scrollbarWidth: "thin",
    scrollbarColor: "transparent transparent",
    "&:hover, &:focus-within": {
        scrollbarColor:
            "color-mix(in srgb, var(--mui-palette-text-base) 20%, transparent) transparent",
    },
    "@supports selector(::-webkit-scrollbar)": {
        scrollbarWidth: "auto",
        scrollbarColor: "auto",
        "&:hover, &:focus-within": { scrollbarColor: "auto" },
        "&::-webkit-scrollbar": { width: "4px" },
        "&::-webkit-scrollbar-track": { backgroundColor: "transparent" },
        "&::-webkit-scrollbar-thumb": {
            backgroundColor: "transparent",
            borderRadius: "4px",
        },
        "&:hover::-webkit-scrollbar-thumb, &:focus-within::-webkit-scrollbar-thumb":
            {
                backgroundColor:
                    "color-mix(in srgb, var(--mui-palette-text-base) 20%, transparent)",
            },
        "&::-webkit-scrollbar-button": { display: "none" },
    },
});

interface RowData extends Omit<NavigationListProps, "collapsed"> {
    tabStopIndex: number;
    pendingFocus: React.RefObject<number | string | undefined>;
    onFocus: (id: number | string) => void;
}

const NavigationRow = memo(
    ({ index, style, data }: ListChildComponentProps<RowData>) => {
        const entry = data.entries[index]!;
        const selected = entry.id === data.activeID;
        const label = entry.name || t("unnamed_person");
        return (
            <div style={style}>
                <ButtonBase
                    ref={(button) => {
                        if (button && data.pendingFocus.current === entry.id) {
                            data.pendingFocus.current = undefined;
                            button.focus();
                        }
                    }}
                    data-navigation-index={index}
                    aria-label={label}
                    aria-current={selected ? "true" : undefined}
                    title={label}
                    tabIndex={data.tabStopIndex === index ? 0 : -1}
                    onFocus={() => data.onFocus(entry.id)}
                    onClick={() => data.onSelect(entry.id)}
                    sx={{
                        display: "flex",
                        justifyContent: "flex-start",
                        gap: "12px",
                        width: "100%",
                        height: data.mobile ? 44 : 48,
                        pl: "16px",
                        pr: "12px",
                        borderRadius: "12px",
                        color: "text.base",
                        textAlign: "left",
                        bgcolor: selected
                            ? "var(--gallery-navigation-surface)"
                            : "transparent",
                        "&:hover": {
                            bgcolor: "var(--gallery-navigation-hover)",
                        },
                        "&.Mui-focusVisible": {
                            outline: "2px solid",
                            outlineColor: "stroke.base",
                            outlineOffset: -2,
                        },
                    }}
                >
                    <Box
                        aria-hidden
                        sx={{
                            flexShrink: 0,
                            overflow: "hidden",
                            borderRadius:
                                typeof entry.id == "string" ? "50%" : "6px",
                        }}
                    >
                        <ItemCard
                            key={`${entry.id}-${entry.coverFile?.id}-${entry.faceID}`}
                            TileComponent={NavigationThumbnail}
                            coverFile={entry.coverFile}
                            coverFaceID={entry.faceID}
                        />
                    </Box>
                    {entry.name && (
                        <Typography
                            noWrap
                            sx={{
                                flex: 1,
                                minWidth: 0,
                                fontFamily:
                                    '"Inter Variable", Inter, sans-serif',
                                fontSize: data.mobile ? 13 : 14,
                                fontWeight: 500,
                                lineHeight: "20px",
                            }}
                        >
                            {entry.name}
                        </Typography>
                    )}
                    {entry.badges.length > 0 && (
                        <Stack
                            aria-hidden
                            direction="row"
                            sx={{
                                flexShrink: 0,
                                ml: "auto",
                                alignItems: "center",
                                gap: "4px",
                                color: "#969696",
                            }}
                        >
                            {entry.badges}
                        </Stack>
                    )}
                </ButtonBase>
            </div>
        );
    },
    areEqual,
);

const NavigationThumbnail = styled("div")({
    width: 24,
    height: 24,
    position: "relative",
    overflow: "hidden",
    "& > img": {
        width: "100%",
        height: "100%",
        objectFit: "cover",
        display: "block",
    },
    "& .MuiSvgIcon-root": { fontSize: 18 },
});

const collectionBadges = (attributes: Set<CollectionSummaryAttribute>) => {
    const badges: ReactNode[] = [];
    if (attributes.has("userFavorites"))
        badges.push(
            <HugeiconsIcon
                key="favorite"
                icon={StarIcon}
                size={16}
                fill="currentColor"
            />,
        );
    if (attributes.has("pinned") || attributes.has("shareePinned"))
        badges.push(<PushPinIcon key="pin" sx={{ fontSize: 14 }} />);
    if (attributes.has("shared") && !attributes.has("sharedOnlyViaLink"))
        badges.push(<PeopleIcon key="people" sx={{ fontSize: 16 }} />);
    if (attributes.has("sharedViaLink"))
        badges.push(<HugeiconsIcon key="link" icon={Link05Icon} size={16} />);
    if (attributes.has("archived"))
        badges.push(
            <ArchiveIcon key="archive" sx={{ fontSize: 16, opacity: 0.48 }} />,
        );
    return badges;
};

const useCollectionsSortByLocalState = () => {
    const [value, setValue] = useState<CollectionsSortBy>("updation-time-desc");
    useEffect(() => {
        const stored = localStorage.getItem("collectionsSortBy");
        if (stored && includes(collectionSortOptions, stored)) setValue(stored);
    }, []);
    const setter = (next: CollectionsSortBy) => {
        localStorage.setItem("collectionsSortBy", next);
        setValue(next);
    };
    return [value, setter] as const;
};
