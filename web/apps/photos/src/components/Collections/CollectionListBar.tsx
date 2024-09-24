import { useIsMobileWidth } from "@/base/hooks";
import { CollectionsSortOptions } from "@/new/photos/components/CollectionsSortOptions";
import { BarItemTile, ItemCard } from "@/new/photos/components/ItemCards";
import { FilledIconButton } from "@/new/photos/components/mui-custom";
import {
    IMAGE_CONTAINER_MAX_WIDTH,
    MIN_COLUMNS,
} from "@/new/photos/components/PhotoList";
import type { Person } from "@/new/photos/services/ml/cgroups";
import type {
    CollectionSummary,
    CollectionSummaryType,
    CollectionsSortBy,
} from "@/new/photos/types/collection";
import { ensure } from "@/utils/ensure";
import { Overlay } from "@ente/shared/components/Container";
import ArchiveIcon from "@mui/icons-material/Archive";
import ExpandMore from "@mui/icons-material/ExpandMore";
import Favorite from "@mui/icons-material/FavoriteRounded";
import LinkIcon from "@mui/icons-material/Link";
import NavigateNextIcon from "@mui/icons-material/NavigateNext";
import PeopleIcon from "@mui/icons-material/People";
import PushPin from "@mui/icons-material/PushPin";
import { Box, IconButton, Stack, Typography, styled } from "@mui/material";
import Tooltip from "@mui/material/Tooltip";
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
import { FixedSizeList, ListChildComponentProps, areEqual } from "react-window";

/**
 * Specifies what the bar is displaying currently.
 */
export type GalleryBarMode = "albums" | "hidden-albums" | "people";

export interface CollectionListBarProps {
    /**
     * What are we displaying currently.
     */
    mode: GalleryBarMode;
    /**
     * Called when the user switches to a different view.
     */
    setMode: (mode: GalleryBarMode) => void;
    /**
     * Massaged data about the collections that should be shown in the bar.
     */
    collectionSummaries: CollectionSummary[];
    /**
     * The ID of the currently active collection (if any)
     */
    activeCollectionID?: number;
    /**
     * Called when the user changes the active collection.
     */
    setActiveCollectionID: (id?: number) => void;
    /**
     * Called when the user selects the option to show a modal with all the
     * collections.
     */
    onShowAllCollections: () => void;
    /**
     * The scheme that should be used for sorting the collections in the bar.
     */
    collectionsSortBy: CollectionsSortBy;
    /**
     * Called when the user changes the sorting scheme.
     */
    onChangeCollectionsSortBy: (by: CollectionsSortBy) => void;
    /**
     * The list of people that should be shown in the bar.
     */
    people: Person[];
    /**
     * The currently selected person (if any).
     */
    activePerson: Person | undefined;
    /**
     * Called when the user selects the given person in the bar.
     */
    onSelectPerson: (person: Person) => void;
}

// TODO-Cluster Rename me to GalleryBarImpl
export const CollectionListBar: React.FC<CollectionListBarProps> = ({
    mode,
    setMode,
    collectionSummaries,
    activeCollectionID,
    setActiveCollectionID,
    onShowAllCollections,
    collectionsSortBy,
    onChangeCollectionsSortBy,
    people,
    activePerson,
    onSelectPerson,
}) => {
    const isMobile = useIsMobileWidth();

    const [canScrollLeft, setCanScrollLeft] = useState(false);
    const [canScrollRight, setCanScrollRight] = useState(false);

    const listContainerRef = useRef<HTMLDivElement>(null);
    const listRef = useRef(null);

    const updateScrollState = useCallback(() => {
        if (!listContainerRef.current) return;

        const { scrollLeft, scrollWidth, clientWidth } =
            listContainerRef.current;

        setCanScrollLeft(scrollLeft > 0);
        setCanScrollRight(scrollLeft + clientWidth < scrollWidth);
    }, []);

    // Maintain a ref to the list container with a combo of a callback and a
    // regular ref.
    //
    // Using just a regular ref doesn't work - it is initially null, so
    // updateScrollState is a no-op. Subsequently, react-window sets it to the
    // correct element, but updateScrollState doesn't run, unless we add
    // listContainerRef.current as a dependency. But that is just hacky.
    //
    // So instead we use a "callback ref", where we both act on the latest
    // value, and also save it in a regular ref so that we can subsequently use
    // it if the scroll position changes because of other, non-DOM, reasons
    // (e.g. if the list of collections changes).

    const listContainerCallbackRef = useCallback(
        (ref) => {
            listContainerRef.current = ref;
            if (!ref) return;

            // Listen for scrolls and resize.
            ref.addEventListener("scroll", updateScrollState);
            const observer = new ResizeObserver(updateScrollState);
            observer.observe(ref);

            // Call handler right away so that state gets updated for the
            // initial size.
            updateScrollState();

            // Remove listeners on cleanup.
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
        listContainerRef.current.scrollBy(250 * direction, 0);

    useEffect(() => {
        if (!listRef.current) return;
        // Scroll the active item into view.
        let i = -1;
        switch (mode) {
            case "albums":
            case "hidden-albums":
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
            mode == "albums" || mode == "hidden-albums"
                ? {
                      type: "collections",
                      collectionSummaries,
                      activeCollectionID,
                      onCollectionClick: setActiveCollectionID,
                  }
                : { type: "people", people, activePerson, onSelectPerson },
        [
            mode,
            collectionSummaries,
            activeCollectionID,
            setActiveCollectionID,
            people,
            activePerson,
            onSelectPerson,
        ],
    );

    const controls1 = isMobile && (
        <Box display="flex" alignItems={"center"} gap={1}>
            <CollectionsSortOptions
                activeSortBy={collectionsSortBy}
                onChangeSortBy={onChangeCollectionsSortBy}
                disableTriggerButtonBackground
            />
            <IconButton onClick={onShowAllCollections}>
                <ExpandMore />
            </IconButton>
        </Box>
    );

    const controls2 = !isMobile && (
        <Box display="flex" alignItems={"center"} gap={1} height={"64px"}>
            <CollectionsSortOptions
                activeSortBy={collectionsSortBy}
                onChangeSortBy={onChangeCollectionsSortBy}
            />
            <FilledIconButton onClick={onShowAllCollections}>
                <ExpandMore />
            </FilledIconButton>
        </Box>
    );

    return (
        <BarWrapper>
            <Row1>
                <ModeIndicator {...{ mode, setMode }} />
                {controls1}
            </Row1>
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
                        <ScrollButtonRight onClick={scroll(+1)} />
                    )}
                </ListWrapper>
                {controls2}
            </Row2>
        </BarWrapper>
    );
};

const BarWrapper = styled(Box)`
    padding-inline: 24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * MIN_COLUMNS}px) {
        padding-inline: 4px;
    }
    margin-block-end: 16px;
    border-block-end: 1px solid ${({ theme }) => theme.palette.divider};
`;

export const Row1 = styled(Box)`
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    margin-block-end: 8px;
`;

export const Row2 = styled(Box)`
    display: flex;
    align-items: flex-start;
    gap: 16px;
`;

const ModeIndicator: React.FC<
    Pick<CollectionListBarProps, "mode" | "setMode">
> = ({ mode }) => (
    <Stack direction="row" sx={{ gap: "10px" }}>
        <Typography color={mode == "people" ? "text.muted" : "text.base"}>
            {mode == "hidden-albums" ? t("hidden_albums") : t("albums")}
        </Typography>
        {process.env.NEXT_PUBLIC_ENTE_WIP_CL && (
            <Typography color={mode == "people" ? "text.base" : "text.muted"}>
                {t("people")}
            </Typography>
        )}
    </Stack>
);

// // TODO-Cluster
// const PeopleHeaderButton = styled("button")(
//     ({ theme }) => `
//     /* Reset some button defaults that are affecting us */
//     background: transparent;
//     border: 0;
//     padding: 0;
//     font: inherit;
//     /* Button should do this for us, but it isn't working inside the select */
//     cursor: pointer;
//     /* The color for the chevron */
//     color: ${theme.colors.stroke.muted};
//     /* Hover indication */
//     && :hover {
//         color: ${theme.colors.stroke.base};
//     }
// `,
// );

const ScrollButtonBase: React.FC<
    React.ButtonHTMLAttributes<HTMLButtonElement>
> = (props) => (
    <ScrollButtonBase_ {...props}>
        <NavigateNextIcon />
    </ScrollButtonBase_>
);

const ScrollButtonBase_ = styled("button")`
    position: absolute;
    z-index: 2;
    top: 7px;
    height: 50px;
    width: 50px;
    border: none;
    padding: 0;
    margin: 0;

    border-radius: 50%;
    background-color: ${({ theme }) => theme.colors.backdrop.muted};
    color: ${({ theme }) => theme.colors.stroke.base};

    & > svg {
        border-radius: 50%;
        height: 30px;
        width: 30px;
    }
`;

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

const ListWrapper = styled(Box)`
    position: relative;
    overflow: hidden;
    height: 86px;
    width: 100%;
`;

type ItemData =
    | {
          type: "collections";
          collectionSummaries: CollectionSummary[];
          activeCollectionID?: number;
          onCollectionClick: (id: number) => void;
      }
    | {
          type: "people";
          people: Person[];
          activePerson: Person;
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
            const collectionSummary = ensure(data.collectionSummaries[index]);
            return `${data.type}-${collectionSummary.id}-${collectionSummary.coverFile?.id}`;
        }
        case "people": {
            const person = ensure(data.people[index]);
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
                onCollectionClick,
            } = data;
            const collectionSummary = ensure(collectionSummaries[index]);
            card = (
                <CollectionBarCard
                    key={collectionSummary.id}
                    activeCollectionID={activeCollectionID}
                    collectionSummary={collectionSummary}
                    onCollectionClick={onCollectionClick}
                />
            );
            break;
        }

        case "people": {
            const { people, activePerson } = data;
            const person = ensure(people[index]);
            card = <PersonCard {...{ person, activePerson }} />;
            break;
        }
    }

    return <div style={style}>{card}</div>;
}, areEqual);

interface CollectionBarCardProps {
    collectionSummary: CollectionSummary;
    activeCollectionID: number;
    onCollectionClick: (collectionID: number) => void;
}

const CollectionBarCard: React.FC<CollectionBarCardProps> = ({
    collectionSummary,
    activeCollectionID,
    onCollectionClick,
}: CollectionBarCardProps) => (
    <div>
        <ItemCard
            TileComponent={BarItemTile}
            coverFile={collectionSummary.coverFile}
            onClick={() => onCollectionClick(collectionSummary.id)}
        >
            <CardText text={collectionSummary.name} />
            <CollectionBarCardIcon type={collectionSummary.type} />
        </ItemCard>
        {activeCollectionID === collectionSummary.id && <ActiveIndicator />}
    </div>
);

interface CardTextProps {
    text: string;
}

const CardText: React.FC<CardTextProps> = ({ text }) => (
    <CardText_>
        <TruncatedText {...{ text }} />
    </CardText_>
);

const CardText_ = styled(Overlay)`
    padding: 4px;
    background: linear-gradient(
        0deg,
        rgba(0, 0, 0, 0.1) 0%,
        rgba(0, 0, 0, 0.5) 86.46%
    );
`;

const TruncatedText: React.FC<CardTextProps> = ({ text }) => (
    <Tooltip title={text}>
        <Box height={"2.1em"} overflow="hidden">
            <Ellipsized variant="small" sx={{ wordBreak: "break-word" }}>
                {text}
            </Ellipsized>
        </Box>
    </Tooltip>
);

const Ellipsized = styled(Typography)`
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2; // number of lines to show
    line-clamp: 2;
    -webkit-box-orient: vertical;
`;

interface CollectionBarCardIconProps {
    type: CollectionSummaryType;
}

const CollectionBarCardIcon: React.FC<CollectionBarCardIconProps> = ({
    type,
}) => (
    <CollectionBarCardIcon_>
        {type == "favorites" && <Favorite />}
        {type == "archived" && (
            <ArchiveIcon
                sx={(theme) => ({
                    color: theme.colors.white.muted,
                })}
            />
        )}
        {type == "outgoingShare" && <PeopleIcon />}
        {(type == "incomingShareViewer" ||
            type == "incomingShareCollaborator") && <PeopleIcon />}
        {type == "sharedOnlyViaLink" && <LinkIcon />}
        {type == "pinned" && <PushPin />}
    </CollectionBarCardIcon_>
);

const CollectionBarCardIcon_ = styled(Overlay)`
    padding: 4px;
    display: flex;
    justify-content: flex-start;
    align-items: flex-end;
    & > .MuiSvgIcon-root {
        font-size: 20px;
    }
`;

const ActiveIndicator = styled("div")`
    height: 3px;
    background-color: ${({ theme }) => theme.palette.primary.main};
    margin-top: 18px;
    border-radius: 2px;
`;

interface PersonCardProps {
    person: Person;
    activePerson: Person;
    // onCollectionClick: (collectionID: number) => void;
}

const PersonCard = ({ person, activePerson }: PersonCardProps) => (
    <Box>
        <ItemCard
            TileComponent={BarItemTile}
            coverFile={person.displayFaceFile}
            onClick={() => {
                //onCollectionClick(collectionSummary.id);
            }}
        >
            <CardText text={person.name} />
        </ItemCard>
        {activePerson.id === person.id && <ActiveIndicator />}
    </Box>
);
