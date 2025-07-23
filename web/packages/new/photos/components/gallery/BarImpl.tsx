import ArchiveIcon from "@mui/icons-material/Archive";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import FavoriteRoundedIcon from "@mui/icons-material/FavoriteRounded";
import LinkIcon from "@mui/icons-material/Link";
import NavigateNextIcon from "@mui/icons-material/NavigateNext";
import PeopleIcon from "@mui/icons-material/People";
import PushPinIcon from "@mui/icons-material/PushPin";
import { Box, IconButton, Stack, Typography, styled } from "@mui/material";
import { Overlay } from "ente-base/components/containers";
import { FilledIconButton } from "ente-base/components/mui";
import { Ellipsized2LineTypography } from "ente-base/components/Typography";
import { useIsSmallWidth } from "ente-base/components/utils/hooks";
import { CollectionsSortOptions } from "ente-new/photos/components/CollectionsSortOptions";
import {
    BarItemTile,
    ItemCard,
    TileTextOverlay,
} from "ente-new/photos/components/Tiles";
import { FocusVisibleUnstyledButton } from "ente-new/photos/components/UnstyledButton";
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
    type ListChildComponentProps,
    areEqual,
} from "react-window";
import { isMLSupported } from "../../services/ml";
import type { GalleryBarMode } from "./reducer";

export interface GalleryBarImplProps {
    /**
     * What are we displaying currently.
     */
    mode: GalleryBarMode;
    /**
     * Called when the user selects to a different mode than the current one.
     */
    onChangeMode: (mode: GalleryBarMode) => void;
    /**
     * Massaged data about the collections that should be shown in the bar.
     */
    collectionSummaries: CollectionSummary[];
    /**
     * The ID of the currently active collection (if any).
     *
     * Required if mode is not "albums" or "hidden-albums".
     */
    activeCollectionID: number | undefined;
    /**
     * Called when the user selects a new collection in the bar.
     *
     * This callback is passed the id of the selected collection.
     */
    onSelectCollectionID: (collectionID: number) => void;
    /**
     * Called when the user selects the option to show a modal with all the
     * albums.
     */
    onShowAllAlbums: () => void;
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
     * The currently selected person, if any.
     */
    activePerson: Person | undefined;
    /**
     * Called when the selection should be moved to a new person in the bar.
     */
    onSelectPerson: (personID: string) => void;
}

export const GalleryBarImpl: React.FC<GalleryBarImplProps> = ({
    mode,
    onChangeMode,
    collectionSummaries,
    activeCollectionID,
    onSelectCollectionID,
    onShowAllAlbums,
    collectionsSortBy,
    onChangeCollectionsSortBy,
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

    const listContainerCallbackRef = useCallback<
        (ref: HTMLDivElement | null) => void
    >(
        (ref) => {
            listContainerRef.current = ref;
            if (!ref) return undefined;

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
        listContainerRef.current?.scrollBy(250 * direction, 0);

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
            {mode != "people" && (
                <>
                    <CollectionsSortOptions
                        activeSortBy={collectionsSortBy}
                        onChangeSortBy={onChangeCollectionsSortBy}
                        transparentTriggerButtonBackground
                    />
                    <IconButton onClick={onShowAllAlbums}>
                        <ExpandMoreIcon />
                    </IconButton>
                </>
            )}
        </Stack>
    );

    const controls2 = !isSmallWidth && mode != "people" && (
        <Stack
            direction="row"
            sx={{ alignItems: "center", gap: 1, height: "64px" }}
        >
            <CollectionsSortOptions
                activeSortBy={collectionsSortBy}
                onChangeSortBy={onChangeCollectionsSortBy}
            />
            <FilledIconButton onClick={onShowAllAlbums}>
                <ExpandMoreIcon />
            </FilledIconButton>
        </Stack>
    );

    return (
        <BarWrapper
            // Hide the bottom border when showing the empty state for people.
            style={
                {
                    "--et-bar-bottom-border-color":
                        mode == "people" && people.length == 0
                            ? "transparent"
                            : "var(--mui-palette-divider)",
                } as React.CSSProperties
            }
        >
            <Row1>
                <ModeIndicator {...{ mode, onChangeMode }} />
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

const BarWrapper = styled("div")`
    padding-inline: 24px;
    @media (max-width: ${thumbnailMaxWidth * thumbnailLayoutMinColumns}px) {
        padding-inline: 4px;
    }
    margin-block-end: 16px;
`;

export const Row1 = styled("div")`
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    margin-block-end: 12px;
`;

export const Row2 = styled("div")`
    display: flex;
    align-items: flex-start;
    gap: 16px;
    border-block-end: 1px solid var(--et-bar-bottom-border-color);
`;

const ModeIndicator: React.FC<
    Pick<GalleryBarImplProps, "mode" | "onChangeMode">
> = ({ mode, onChangeMode }) => {
    // Mode switcher is not shown in the hidden albums section.
    if (mode == "hidden-albums") {
        return <Typography>{t("hidden_albums")}</Typography>;
    }

    // Show the static mode indicator with only the "Albums" title if ML is not
    // supported on this client (web), since there are no other sections to
    // switch to in such a case.
    if (!isMLSupported) {
        return <Typography>{t("albums")}</Typography>;
    }

    return (
        <Stack direction="row" sx={{ gap: "10px" }}>
            <ModeButton
                active={mode == "albums"}
                onClick={() => onChangeMode("albums")}
            >
                <Typography>{t("albums")}</Typography>
            </ModeButton>
            <ModeButton
                active={mode == "people"}
                onClick={() => onChangeMode("people")}
            >
                <Typography>{t("people")}</Typography>
            </ModeButton>
        </Stack>
    );
};

const ModeButton = styled(FocusVisibleUnstyledButton, {
    shouldForwardProp: (propName) => propName != "active",
})<{ active: boolean }>(
    ({ theme, active }) => `
p {
    color: ${active ? theme.vars.palette.text.base : theme.vars.palette.text.muted}
}
p:hover {
    color: ${theme.vars.palette.text.base}
}
`,
);

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
    // Under current scenarios, there are no cases where more than 3 of these
    // will be true simultaneously even in the rarest of cases (a pinned and
    // shared album that is also archived), and there is enough space for 3.
    <CollectionBarCardIcon_>
        {attributes.has("userFavorites") && <FavoriteRoundedIcon />}
        {attributes.has("pinned") && (
            // Need && to override the 20px set in the container.
            <PushPinIcon sx={{ "&&": { fontSize: "18px" } }} />
        )}
        {attributes.has("shared") &&
            (attributes.has("sharedOnlyViaLink") ? (
                <LinkIcon />
            ) : (
                <PeopleIcon />
            ))}
        {attributes.has("archived") && <ArchiveIcon sx={{ opacity: 0.48 }} />}
    </CollectionBarCardIcon_>
);

const CollectionBarCardIcon_ = styled(Overlay)`
    padding: 4px;
    display: flex;
    justify-content: flex-start;
    align-items: flex-end;
    gap: 4px;
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
        </ItemCard>
        {activePerson?.id === person.id && <ActiveIndicator />}
    </div>
);
