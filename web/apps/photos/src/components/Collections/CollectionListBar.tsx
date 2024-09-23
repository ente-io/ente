import { useIsMobileWidth } from "@/base/hooks";
import type { Person } from "@/new/photos/services/ml/cgroups";
import type { CollectionSummary } from "@/new/photos/types/collection";
import {
    IconButtonWithBG,
    Overlay,
    SpaceBetweenFlex,
} from "@ente/shared/components/Container";
import useWindowSize from "@ente/shared/hooks/useWindowSize";
import ArchiveIcon from "@mui/icons-material/Archive";
import ExpandMore from "@mui/icons-material/ExpandMore";
import Favorite from "@mui/icons-material/FavoriteRounded";
import LinkIcon from "@mui/icons-material/Link";
import NavigateNextIcon from "@mui/icons-material/NavigateNext";
import PeopleIcon from "@mui/icons-material/People";
import PushPin from "@mui/icons-material/PushPin";
import { Box, IconButton, Stack, Typography, styled } from "@mui/material";
import Tooltip from "@mui/material/Tooltip";
import { CollectionTile } from "components/Collections/styledComponents";
import {
    IMAGE_CONTAINER_MAX_WIDTH,
    MIN_COLUMNS,
} from "components/PhotoList/constants";
import { t } from "i18next";
import memoize from "memoize-one";
import React, { useEffect, useRef, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { FixedSizeList, ListChildComponentProps, areEqual } from "react-window";
import { ALL_SECTION, COLLECTION_LIST_SORT_BY } from "utils/collection";
import type { GalleryBarMode } from ".";
import CollectionCard from "./CollectionCard";
import CollectionListSortBy from "./CollectionListSortBy";

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
     * The sort order that should be used for showing the collections in the
     * bar.
     */
    collectionListSortBy: COLLECTION_LIST_SORT_BY;
    /**
     * Called when the user changes the sort order.
     */
    setCollectionListSortBy: (v: COLLECTION_LIST_SORT_BY) => void;
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

export const CollectionListBar: React.FC<CollectionListBarProps> = ({
    mode,
    collectionSummaries,
    activeCollectionID,
    setActiveCollectionID,
    onShowAllCollections,
    collectionListSortBy,
    setCollectionListSortBy,
    // people,
    // activePerson,
    // onSelectPerson
}) => {
    const windowSize = useWindowSize();
    const isMobile = useIsMobileWidth();

    const collectionListWrapperRef = useRef<HTMLDivElement>(null);
    const collectionListRef = React.useRef(null);

    const [scrollObj, setScrollObj] = useState<{
        scrollLeft?: number;
        scrollWidth?: number;
        clientWidth?: number;
    }>({});

    const updateScrollObj = () => {
        if (!collectionListWrapperRef.current) {
            return;
        }
        const { scrollLeft, scrollWidth, clientWidth } =
            collectionListWrapperRef.current;
        setScrollObj({ scrollLeft, scrollWidth, clientWidth });
    };

    useEffect(() => {
        if (!collectionListWrapperRef.current) {
            return;
        }
        // Add event listener
        collectionListWrapperRef.current?.addEventListener(
            "scroll",
            updateScrollObj,
        );

        // Call handler right away so state gets updated with initial window size
        updateScrollObj();
        // Remove event listener on cleanup
        return () =>
            collectionListWrapperRef.current?.removeEventListener(
                "resize",
                updateScrollObj,
            );
    }, [collectionListWrapperRef.current]);

    useEffect(() => {
        updateScrollObj();
    }, [windowSize, collectionSummaries]);

    const scrollComponent = (direction: number) => () => {
        collectionListWrapperRef.current.scrollBy(250 * direction, 0);
    };

    const onFarLeft = scrollObj.scrollLeft === 0;
    const onFarRight =
        scrollObj.scrollLeft + scrollObj.clientWidth === scrollObj.scrollWidth;

    useEffect(() => {
        if (!collectionListRef.current) {
            return;
        }
        // scroll the active collection into view
        const activeCollectionIndex = collectionSummaries.findIndex(
            (item) => item.id === activeCollectionID,
        );
        collectionListRef.current.scrollToItem(activeCollectionIndex, "smart");
    }, [activeCollectionID]);

    const onCollectionClick = (collectionID?: number) => {
        setActiveCollectionID(collectionID ?? ALL_SECTION);
    };

    const itemData = createItemData(
        collectionSummaries,
        activeCollectionID,
        onCollectionClick,
    );

    return (
        <CollectionListBarWrapper>
            <SpaceBetweenFlex mb={1}>
                <Stack direction="row" gap={1}>
                    <Typography
                        color={mode == "people" ? "text.muted" : "text.base"}
                    >
                        {mode == "hidden-albums"
                            ? t("hidden_albums")
                            : t("albums")}
                    </Typography>
                    {process.env.NEXT_PUBLIC_ENTE_WIP_CL && (
                        <Typography
                            color={
                                mode == "people" ? "text.base" : "text.muted"
                            }
                        >
                            {t("people")}
                        </Typography>
                    )}
                </Stack>
                {isMobile && (
                    <Box display="flex" alignItems={"center"} gap={1}>
                        <CollectionListSortBy
                            setSortBy={setCollectionListSortBy}
                            activeSortBy={collectionListSortBy}
                            disableBG
                        />
                        <IconButton onClick={onShowAllCollections}>
                            <ExpandMore />
                        </IconButton>
                    </Box>
                )}
            </SpaceBetweenFlex>
            <Box display="flex" alignItems="flex-start" gap={2}>
                <CollectionListWrapper>
                    {!onFarLeft && (
                        <ScrollButtonLeft onClick={scrollComponent(-1)} />
                    )}
                    <AutoSizer disableHeight>
                        {({ width }) => (
                            <FixedSizeList
                                ref={collectionListRef}
                                outerRef={collectionListWrapperRef}
                                itemData={itemData}
                                layout="horizontal"
                                width={width}
                                height={110}
                                itemKey={getItemKey}
                                itemCount={collectionSummaries.length}
                                itemSize={CollectionListBarCardWidth}
                                useIsScrolling
                            >
                                {CollectionCardContainer}
                            </FixedSizeList>
                        )}
                    </AutoSizer>
                    {!onFarRight && (
                        <ScrollButtonRight onClick={scrollComponent(+1)} />
                    )}
                </CollectionListWrapper>
                {!isMobile && (
                    <Box
                        display="flex"
                        alignItems={"center"}
                        gap={1}
                        height={"64px"}
                    >
                        <CollectionListSortBy
                            setSortBy={setCollectionListSortBy}
                            activeSortBy={collectionListSortBy}
                        />
                        <IconButtonWithBG onClick={onShowAllCollections}>
                            <ExpandMore />
                        </IconButtonWithBG>
                    </Box>
                )}
            </Box>
        </CollectionListBarWrapper>
    );
};

const CollectionListBarWrapper = styled(Box)`
    padding-inline: 24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * MIN_COLUMNS}px) {
        padding-inline: 4px;
    }
    margin-block-end: 16px;
    border-block-end: 1px solid ${({ theme }) => theme.palette.divider};
`;

const CollectionListWrapper = styled(Box)`
    position: relative;
    overflow: hidden;
    height: 86px;
    width: 100%;
`;

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

interface ItemData {
    collectionSummaries: CollectionSummary[];
    activeCollectionID?: number;
    onCollectionClick: (id?: number) => void;
}

const CollectionListBarCardWidth = 94;

const createItemData = memoize(
    (collectionSummaries, activeCollectionID, onCollectionClick) => ({
        collectionSummaries,
        activeCollectionID,
        onCollectionClick,
    }),
);

const CollectionCardContainer = React.memo(
    ({
        data,
        index,
        style,
        isScrolling,
    }: ListChildComponentProps<ItemData>) => {
        const { collectionSummaries, activeCollectionID, onCollectionClick } =
            data;

        const collectionSummary = collectionSummaries[index];

        return (
            <div style={style}>
                <CollectionListBarCard
                    key={collectionSummary.id}
                    activeCollectionID={activeCollectionID}
                    isScrolling={isScrolling}
                    collectionSummary={collectionSummary}
                    onCollectionClick={onCollectionClick}
                />
            </div>
        );
    },
    areEqual,
);

const getItemKey = (index: number, data: ItemData) => {
    return `${data.collectionSummaries[index].id}-${data.collectionSummaries[index].coverFile?.id}`;
};

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

interface CollectionListBarCardProps {
    collectionSummary: CollectionSummary;
    activeCollectionID: number;
    onCollectionClick: (collectionID: number) => void;
    isScrolling?: boolean;
}

const CollectionListBarCard = (props: CollectionListBarCardProps) => {
    const { activeCollectionID, collectionSummary, onCollectionClick } = props;

    return (
        <Box>
            <CollectionCard
                collectionTile={CollectionBarTile}
                coverFile={collectionSummary.coverFile}
                onClick={() => {
                    onCollectionClick(collectionSummary.id);
                }}
            >
                <CollectionCardText collectionName={collectionSummary.name} />
                <CollectionCardIcon collectionType={collectionSummary.type} />
            </CollectionCard>
            {activeCollectionID === collectionSummary.id && <ActiveIndicator />}
        </Box>
    );
};

const ActiveIndicator = styled("div")`
    height: 3px;
    background-color: ${({ theme }) => theme.palette.primary.main};
    margin-top: 18px;
    border-radius: 2px;
`;

const CollectionBarTile = styled(CollectionTile)`
    width: 90px;
    height: 64px;
`;

const CollectionBarTileText = styled(Overlay)`
    padding: 4px;
    background: linear-gradient(
        0deg,
        rgba(0, 0, 0, 0.1) 0%,
        rgba(0, 0, 0, 0.5) 86.46%
    );
`;

const CollectionBarTileIcon = styled(Overlay)`
    padding: 4px;
    display: flex;
    justify-content: flex-start;
    align-items: flex-end;
    & > .MuiSvgIcon-root {
        font-size: 20px;
    }
`;

function CollectionCardText({ collectionName }) {
    return (
        <CollectionBarTileText>
            <TruncateText text={collectionName} />
        </CollectionBarTileText>
    );
}

function CollectionCardIcon({ collectionType }) {
    return (
        <CollectionBarTileIcon>
            {collectionType == "favorites" && <Favorite />}
            {collectionType == "archived" && (
                <ArchiveIcon
                    sx={(theme) => ({
                        color: theme.colors.white.muted,
                    })}
                />
            )}
            {collectionType == "outgoingShare" && <PeopleIcon />}
            {(collectionType == "incomingShareViewer" ||
                collectionType == "incomingShareCollaborator") && (
                <PeopleIcon />
            )}
            {collectionType == "sharedOnlyViaLink" && <LinkIcon />}
            {collectionType == "pinned" && <PushPin />}
        </CollectionBarTileIcon>
    );
}

const TruncateText = ({ text }) => {
    return (
        <Tooltip title={text}>
            <Box height={"2.1em"} overflow="hidden">
                <Ellipse variant="small" sx={{ wordBreak: "break-word" }}>
                    {text}
                </Ellipse>
            </Box>
        </Tooltip>
    );
};

const Ellipse = styled(Typography)`
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2; //number of lines to show
    line-clamp: 2;
    -webkit-box-orient: vertical;
`;
