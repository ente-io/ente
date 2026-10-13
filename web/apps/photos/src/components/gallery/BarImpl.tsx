import { CollectionsSortOptions } from "@/components/CollectionsSortOptions";
import { PeopleSortOptions } from "@/components/PeopleSortOptions";
import type { PeopleSortBy } from "@/utils/people-sort";
import { Link05Icon, PinIcon, StarIcon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import ArchiveIcon from "@mui/icons-material/Archive";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import NavigateNextIcon from "@mui/icons-material/NavigateNext";
import PeopleIcon from "@mui/icons-material/People";
import { Box, IconButton, Stack, Typography, styled } from "@mui/material";
import { Overlay } from "ente-base/components/containers";
import { FilledIconButton } from "ente-base/components/mui";
import { Ellipsized2LineTypography } from "ente-base/components/Typography";
import { useIsSmallWidth } from "ente-base/components/utils/hooks";
import {
    BarItemTile,
    ItemCard,
    TileTextOverlay,
} from "ente-new/photos/components/Tiles";
import {
    thumbnailLayoutMinColumns,
    thumbnailMaxWidth,
} from "ente-new/photos/components/utils/thumbnail-grid-layout";
import type {
    CollectionSummary,
    CollectionSummaryAttribute,
    CollectionsSortBy,
} from "ente-new/photos/services/collection-summary";
import type { Person } from "ente-new/photos/services/ml/people";
import { t } from "i18next";
import React, {
    memo,
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import {
    FixedSizeList,
    areEqual,
    type ListChildComponentProps,
} from "react-window";
import type { GalleryBarMode } from "./reducer";

export interface GalleryBarImplProps {
    mode: GalleryBarMode;
    collectionSummaries: CollectionSummary[];
    activeCollectionID: number | undefined;
    onSelectCollectionID: (collectionID: number) => void;
    onShowAllAlbums: () => void;
    onShowAllPeople: () => void;
    collectionsSortBy: CollectionsSortBy;
    onChangeCollectionsSortBy: (by: CollectionsSortBy) => void;
    peopleSortBy: PeopleSortBy;
    onChangePeopleSortBy: (by: PeopleSortBy) => void;
    people: Person[];
    activePerson: Person | undefined;
    onSelectPerson: (personID: string) => void;
}

export const GalleryBarImpl: React.FC<GalleryBarImplProps> = ({
    mode,
    collectionSummaries,
    activeCollectionID,
    onSelectCollectionID,
    onShowAllAlbums,
    onShowAllPeople,
    collectionsSortBy,
    onChangeCollectionsSortBy,
    peopleSortBy,
    onChangePeopleSortBy,
    people,
    activePerson,
    onSelectPerson,
}) => {
    const isSmallWidth = useIsSmallWidth();

    const [canScrollLeft, setCanScrollLeft] = useState(false);
    const [canScrollRight, setCanScrollRight] = useState(false);

    const listContainerRef = useRef<HTMLDivElement | null>(null);
    const listRef = useRef<FixedSizeList | null>(null);

    const updateScrollState = useCallback(() => {
        if (!listContainerRef.current) return;

        const { scrollLeft, scrollWidth, clientWidth } =
            listContainerRef.current;

        setCanScrollLeft(scrollLeft > 0);
        setCanScrollRight(scrollLeft + clientWidth < scrollWidth);
    }, []);

    // react-window supplies the DOM node after the first render.
    // The callback ref initializes listeners; the regular ref handles later changes.
    const listContainerCallbackRef = useCallback<
        (ref: HTMLDivElement | null) => void
    >(
        (ref) => {
            listContainerRef.current = ref;
            if (!ref) return undefined;

            ref.addEventListener("scroll", updateScrollState);
            const observer = new ResizeObserver(updateScrollState);
            observer.observe(ref);

            updateScrollState();

            return () => {
                ref.removeEventListener("scroll", updateScrollState);
                observer.unobserve(ref);
            };
        },
        [updateScrollState],
    );

    useEffect(() => {
        updateScrollState();
    }, [updateScrollState, mode, collectionSummaries, people]);

    const scroll = (direction: number) => () =>
        listContainerRef.current?.scrollBy(250 * direction, 0);

    useEffect(() => {
        if (!listRef.current) return;
        let i = -1;
        switch (mode) {
            case "albums":
            case "hidden-albums":
            case "archive-albums":
                i = collectionSummaries.findIndex(
                    ({ id }) => id == activeCollectionID,
                );
                break;
            case "people":
                i = people.findIndex(({ id }) => id == activePerson?.id);
                break;
        }
        if (i != -1) listRef.current.scrollToItem(i, "smart");
    }, [mode, collectionSummaries, activeCollectionID, people, activePerson]);

    const itemData = useMemo<ItemData>(
        () =>
            mode == "albums" ||
            mode == "hidden-albums" ||
            mode == "archive-albums"
                ? {
                      type: "collections",
                      collectionSummaries,
                      activeCollectionID: activeCollectionID!,
                      onSelectCollectionID,
                  }
                : {
                      type: "people" as const,
                      people,
                      activePerson,
                      onSelectPerson,
                  },
        [
            mode,
            collectionSummaries,
            activeCollectionID,
            onSelectCollectionID,
            people,
            activePerson,
            onSelectPerson,
        ],
    );

    const controls1 = isSmallWidth && (
        <Stack
            direction="row"
            sx={{ alignItems: "center", gap: 1, minHeight: "64px" }}
        >
            {mode != "people" ? (
                <CollectionsSortOptions
                    activeSortBy={collectionsSortBy}
                    onChangeSortBy={onChangeCollectionsSortBy}
                    transparentTriggerButtonBackground
                />
            ) : (
                <PeopleSortOptions
                    activeSortBy={peopleSortBy}
                    onChangeSortBy={onChangePeopleSortBy}
                    transparentTriggerButtonBackground
                />
            )}
            <IconButton
                onClick={mode == "people" ? onShowAllPeople : onShowAllAlbums}
            >
                <ExpandMoreIcon />
            </IconButton>
        </Stack>
    );

    const controls2 = !isSmallWidth && (
        <Stack
            direction="row"
            sx={{ alignItems: "center", gap: 1, height: "64px" }}
        >
            {mode != "people" ? (
                <CollectionsSortOptions
                    activeSortBy={collectionsSortBy}
                    onChangeSortBy={onChangeCollectionsSortBy}
                />
            ) : (
                <PeopleSortOptions
                    activeSortBy={peopleSortBy}
                    onChangeSortBy={onChangePeopleSortBy}
                />
            )}
            <FilledIconButton
                onClick={mode == "people" ? onShowAllPeople : onShowAllAlbums}
            >
                <ExpandMoreIcon />
            </FilledIconButton>
        </Stack>
    );

    return (
        <BarWrapper
            style={
                {
                    "--et-bar-bottom-border-color":
                        mode == "people" && people.length == 0
                            ? "transparent"
                            : "var(--mui-palette-divider)",
                } as React.CSSProperties
            }
        >
            {(mode == "hidden-albums" ||
                mode == "archive-albums" ||
                isSmallWidth) && (
                <Row1>
                    {mode == "hidden-albums" ? (
                        <Typography>{t("hidden_albums")}</Typography>
                    ) : mode == "archive-albums" ? (
                        <Typography>{t("section_archive")}</Typography>
                    ) : null}
                    {controls1}
                </Row1>
            )}
            <Row2>
                <ListWrapper>
                    {canScrollLeft && <ScrollButtonLeft onClick={scroll(-1)} />}
                    <AutoSizer disableHeight>
                        {({ width }) => (
                            <FixedSizeList
                                ref={listRef}
                                outerRef={listContainerCallbackRef}
                                layout="horizontal"
                                width={width}
                                height={110}
                                itemData={itemData}
                                itemKey={getItemKey}
                                itemCount={getItemCount(itemData)}
                                itemSize={94}
                            >
                                {ListItem}
                            </FixedSizeList>
                        )}
                    </AutoSizer>
                    {canScrollRight && (
                        <ScrollButtonRight onClick={scroll(1)} />
                    )}
                </ListWrapper>
                {controls2}
            </Row2>
        </BarWrapper>
    );
};

const BarWrapper = styled("div")`
    padding-inline: 24px;
    @media (max-width: ${thumbnailMaxWidth * thumbnailLayoutMinColumns}px) {
        padding-inline: 4px;
    }
    margin-block-end: 16px;
`;

const Row1 = styled("div")`
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    margin-block-end: 12px;
`;

const Row2 = styled("div")`
    display: flex;
    align-items: flex-start;
    gap: 16px;
    border-block-end: 1px solid var(--et-bar-bottom-border-color);
`;

const ScrollButtonBase: React.FC<
    React.ButtonHTMLAttributes<HTMLButtonElement>
> = (props) => (
    <ScrollButtonBase_ {...props}>
        <NavigateNextIcon />
    </ScrollButtonBase_>
);

const ScrollButtonBase_ = styled("button")(({ theme }) => ({
    position: "absolute",
    zIndex: 2,
    top: "7px",
    height: "50px",
    width: "50px",
    border: "none",
    padding: 0,
    margin: 0,
    borderRadius: "50%",
    backgroundColor: theme.vars.palette.backdrop.muted,
    color: theme.vars.palette.stroke.base,
    cursor: "pointer",
    "& > svg": { borderRadius: "50%", height: "30px", width: "30px" },
}));

const ScrollButtonLeft = styled(ScrollButtonBase)`
    left: 0;
    text-align: right;
    transform: translate(-50%, 0%);
    & > svg {
        transform: rotate(180deg);
    }
`;

const ScrollButtonRight = styled(ScrollButtonBase)`
    right: 0;
    text-align: left;
    transform: translate(50%, 0%);
`;

const ListWrapper = styled("div")`
    position: relative;
    overflow: hidden;
    height: 86px;
    width: 100%;
`;

type ItemData =
    | {
          type: "collections";
          collectionSummaries: CollectionSummary[];
          activeCollectionID: number;
          onSelectCollectionID: (id: number) => void;
      }
    | {
          type: "people";
          people: Person[];
          activePerson: Person | undefined;
          onSelectPerson: (personID: string) => void;
      };

const getItemCount = (data: ItemData) => {
    switch (data.type) {
        case "collections": {
            return data.collectionSummaries.length;
        }
        case "people": {
            return data.people.length;
        }
    }
};

const getItemKey = (index: number, data: ItemData) => {
    switch (data.type) {
        case "collections": {
            const collectionSummary = data.collectionSummaries[index]!;
            return `${data.type}-${collectionSummary.id}-${collectionSummary.coverFile?.id}`;
        }
        case "people": {
            const person = data.people[index]!;
            return `${data.type}-${person.id}-${person.displayFaceID}`;
        }
    }
};

const ListItem = memo((props: ListChildComponentProps<ItemData>) => {
    const { data, index, style } = props;

    let card: React.ReactNode;

    switch (data.type) {
        case "collections": {
            const {
                collectionSummaries,
                activeCollectionID,
                onSelectCollectionID,
            } = data;
            const collectionSummary = collectionSummaries[index]!;
            card = (
                <CollectionBarCard
                    key={collectionSummary.id}
                    {...{
                        collectionSummary,
                        activeCollectionID,
                        onSelectCollectionID,
                    }}
                />
            );
            break;
        }

        case "people": {
            const { people, activePerson, onSelectPerson } = data;
            const person = people[index]!;
            card = (
                <PersonCard
                    key={person.id}
                    {...{ person, activePerson, onSelectPerson }}
                />
            );
            break;
        }
    }

    return <div style={style}>{card}</div>;
}, areEqual);

interface CollectionBarCardProps {
    collectionSummary: CollectionSummary;
    activeCollectionID: number;
    onSelectCollectionID: (collectionID: number) => void;
}

const CollectionBarCard: React.FC<CollectionBarCardProps> = ({
    collectionSummary,
    activeCollectionID,
    onSelectCollectionID,
}: CollectionBarCardProps) => (
    <div>
        <ItemCard
            TileComponent={BarItemTile}
            coverFile={collectionSummary.coverFile}
            onClick={() => onSelectCollectionID(collectionSummary.id)}
        >
            <CardText>{collectionSummary.name}</CardText>
            <CollectionBarCardIcon attributes={collectionSummary.attributes} />
        </ItemCard>
        {activeCollectionID === collectionSummary.id && <ActiveIndicator />}
    </div>
);

const CardText: React.FC<React.PropsWithChildren> = ({ children }) => (
    <TileTextOverlay>
        <Box sx={{ height: "2.1em" }}>
            <Ellipsized2LineTypography variant="small">
                {children}
            </Ellipsized2LineTypography>
        </Box>
    </TileTextOverlay>
);

interface CollectionBarCardIconProps {
    attributes: Set<CollectionSummaryAttribute>;
}

const CollectionBarCardIcon: React.FC<CollectionBarCardIconProps> = ({
    attributes,
}) => (
    // A collection can show all four status icons at once.
    <CollectionBarCardIcon_>
        {attributes.has("userFavorites") && (
            <HugeiconsIcon
                icon={StarIcon}
                size={20}
                fill="currentColor"
                aria-hidden
            />
        )}
        {(attributes.has("pinned") || attributes.has("shareePinned")) && (
            <HugeiconsIcon icon={PinIcon} size={18} />
        )}
        {attributes.has("shared") && !attributes.has("sharedOnlyViaLink") && (
            <PeopleIcon />
        )}
        {attributes.has("sharedViaLink") && (
            <HugeiconsIcon icon={Link05Icon} size={20} />
        )}
        {attributes.has("archived") && <ArchiveIcon sx={{ opacity: 0.48 }} />}
    </CollectionBarCardIcon_>
);

const CollectionBarCardIcon_ = styled(Overlay)`
    padding: 3px;
    display: flex;
    justify-content: flex-start;
    align-items: flex-end;
    gap: 2px;
    & > .MuiSvgIcon-root {
        font-size: 20px;
    }
`;

const PersonPinnedIcon = styled(Overlay)`
    padding: 4px;
    display: flex;
    justify-content: flex-start;
    align-items: flex-end;
    color: white;
    z-index: 1;
    & > .MuiSvgIcon-root {
        font-size: 20px;
    }
`;

const ActiveIndicator = styled("div")(
    ({ theme }) => `
    height: 3px;
    background-color: ${theme.vars.palette.stroke.base};
    margin-top: 19px;
    border-radius: 2px;
`,
);

interface PersonCardProps {
    person: Person;
    activePerson: Person | undefined;
    onSelectPerson: (personID: string) => void;
}

const PersonCard: React.FC<PersonCardProps> = ({
    person,
    activePerson,
    onSelectPerson,
}) => (
    <div>
        <ItemCard
            TileComponent={BarItemTile}
            coverFile={person.displayFaceFile}
            coverFaceID={person.displayFaceID}
            onClick={() => onSelectPerson(person.id)}
        >
            {person.name && <CardText>{person.name}</CardText>}
            {person.isPinned && (
                <PersonPinnedIcon>
                    <HugeiconsIcon icon={PinIcon} size={18} color="white" />
                </PersonPinnedIcon>
            )}
        </ItemCard>
        {activePerson?.id === person.id && <ActiveIndicator />}
    </div>
);
