// TODO: Audit this file
import AlbumOutlinedIcon from "@mui/icons-material/AlbumOutlined";
import FavoriteRoundedIcon from "@mui/icons-material/FavoriteRounded";
import PlayCircleOutlineOutlinedIcon from "@mui/icons-material/PlayCircleOutlineOutlined";
import { Box, Checkbox, Typography, styled } from "@mui/material";
import Avatar from "components/Avatar";
import type { LocalUser } from "ente-accounts/services/user";
import { assertionFailed } from "ente-base/assert";
import { Overlay } from "ente-base/components/containers";
import { isSameDay } from "ente-base/date";
import { formattedDateRelative } from "ente-base/i18n-date";
import log from "ente-base/log";
import { downloadManager } from "ente-gallery/services/download";
import type { EnteFile } from "ente-media/file";
import { fileCreationTime, fileDurationString } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import { GAP_BTW_TILES } from "ente-new/photos/components/FileList";
import type { GalleryBarMode } from "ente-new/photos/components/gallery/reducer";
import {
    LoadingThumbnail,
    StaticThumbnail,
} from "ente-new/photos/components/PlaceholderThumbnails";
import { TileBottomTextOverlay } from "ente-new/photos/components/Tiles";
import {
    computeThumbnailGridLayoutParams,
    type ThumbnailGridLayoutParams,
} from "ente-new/photos/components/utils/thumbnail-grid-layout";
import { PseudoCollectionID } from "ente-new/photos/services/collection-summary";
import { t } from "i18next";
import React, {
    memo,
    useCallback,
    useDeferredValue,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import {
    type ListChildComponentProps,
    VariableSizeList,
    areEqual,
} from "react-window";
import { type SelectedState } from "utils/file";
import {
    handleSelectCreator,
    handleSelectCreatorMulti,
} from "utils/photoFrame";

/**
 * A component with an explicit height suitable for being plugged in as the
 * {@link header} or {@link footer} of the {@link FileList}.
 */
export interface FileListHeaderOrFooter {
    /**
     * The component itself.
     */
    component: React.ReactNode;
    /**
     * The height of the component (in px).
     */
    height: number;
    /**
     * By default, all items in the {@link FileList}, including headers and
     * footers injected using this type, get an inline margin.
     *
     * Set this property to `true` to omit this default margin, and instead
     * have the component extend to the container's edges.
     */
    extendToInlineEdges?: boolean;
}

/**
 * Data needed to render each row in the variable size list that comprises the
 * file list.
 */
type FileListItem = {
    /**
     * The height of the row that will render this item.
     */
    height: number;
    /**
     * An optional tag that can be used to identify item types for conditional
     * behaviour.
     */
    tag?: "date" | "file" | "span";
    items?: FileListAnnotatedFile[];
    itemStartIndex?: number;
    date?: string | null;
    dates?: { date: string; span: number }[];
    groups?: number[];
    /**
     * The React component that is the rendered representation of the item.
     */
    component?: React.ReactNode;
} & Pick<FileListHeaderOrFooter, "extendToInlineEdges">;

export interface FileListAnnotatedFile {
    file: EnteFile;
    /**
     * The date string using with the associated {@link file} should be shown in
     * the timeline.
     *
     * [Note: Timeline date string]
     *
     * The timeline date string is a formatted date string under which a
     * particular file should be grouped in the gallery listing. e.g. "Today",
     * "Yesterday", "Fri, 21 Feb" etc.
     *
     * All files which have the same timelineDateString will be grouped under a
     * single section in the gallery listing, prefixed by the timelineDateString
     * itself, and a checkbox to select all files on that date.
     */
    timelineDateString: string;
}

/**
 * A file augmented with the date when it will be permanently deleted.
 *
 * See: [Note: Files in trash pseudo collection have deleteBy]
 */
export type EnteTrashFile = EnteFile & {
    /**
     * Timestamp (epoch microseconds) when the trash item (and its corresponding
     * {@link EnteFile}) will be permanently deleted.
     */
    deleteBy?: number;
};

export interface FileListProps {
    /** The height we should occupy (needed since the list is virtualized). */
    height: number;
    /** The width we should occupy.*/
    width: number;
    /**
     * The files to show, annotated with cached precomputed properties that are
     * frequently needed by the {@link FileList}.
     */
    annotatedFiles: FileListAnnotatedFile[];
    mode?: GalleryBarMode;
    /**
     * This is an experimental prop, to see if we can merge the separate
     * "isInSearchMode" state kept by the gallery to be instead provided as a
     * another mode in which the gallery operates.
     */
    modePlus?: GalleryBarMode | "search";
    /**
     * An optional component shown before all the items in the list.
     *
     * It is not sticky, and scrolls along with the content of the list.
     */
    header?: FileListHeaderOrFooter;
    /**
     * An optional component shown after all the items in the list.
     *
     * It is not sticky, and scrolls along with the content of the list.
     */
    footer?: FileListHeaderOrFooter;
    /**
     * The logged in user, if any.
     *
     * This is only expected to be present when the listing is shown within the
     * photos app, where we have a logged in user. The public albums app can
     * omit this prop.
     */
    user?: LocalUser;
    /**
     * If `true`, then the default behaviour of grouping files by their date is
     * suppressed.
     *
     * This behaviour is used when showing magic search results.
     */
    disableGrouping?: boolean;
    selectable?: boolean;
    setSelected: (
        selected: SelectedState | ((selected: SelectedState) => SelectedState),
    ) => void;
    selected: SelectedState;
    /** This will be set if mode is not "people". */
    activeCollectionID: number;
    /** This will be set if mode is "people". */
    activePersonID?: string | undefined;
    /**
     * File IDs of all the files that the user has marked as a favorite.
     *
     * Not set in the context of the shared albums app.
     */
    favoriteFileIDs?: Set<number>;
    /**
     * A map from known Ente user IDs to their emails.
     *
     * This is only expected in the context of the photos app, and will be
     * omitted when running in the public albums app.
     */
    emailByUserID?: Map<number, string>;
    /**
     * Called when the user activates the thumbnail at the given {@link index}.
     *
     * This corresponding file would be at the corresponding index of
     * {@link annotatedFiles}.
     */
    onItemClick: (index: number) => void;
}

/**
 * A virtualized list of files, each represented by their thumbnail.
 */
export const FileList: React.FC<FileListProps> = ({
    height,
    width,
    mode,
    modePlus,
    header,
    footer,
    user,
    annotatedFiles,
    disableGrouping,
    selectable,
    selected,
    setSelected,
    activeCollectionID,
    activePersonID,
    favoriteFileIDs,
    emailByUserID,
    onItemClick,
}) => {
    const [_items, setItems] = useState<FileListItem[]>([]);
    const items = useDeferredValue(_items);

    const listRef = useRef<VariableSizeList | null>(null);

    // Timeline date strings for which all photos have been selected.
    //
    // See: [Note: Timeline date string]
    const [checkedTimelineDateStrings, setCheckedTimelineDateStrings] =
        useState(new Set());

    const [rangeStart, setRangeStart] = useState<number | null>(null);
    const [currentHover, setCurrentHover] = useState<number | null>(null);
    const [isShiftKeyPressed, setIsShiftKeyPressed] = useState(false);

    const layoutParams = useMemo(
        () => computeThumbnailGridLayoutParams(width),
        [width],
    );

    const {
        // containerWidth,
        // isSmallerLayout,
        // paddingInline,
        columns,
        // itemWidth,
        // itemHeight,
        // gap,
    } = layoutParams;

    useEffect(() => {
        // Since width and height are dependencies, there might be too many
        // updates to the list during a resize. The list computation too, while
        // fast, is non-trivial.
        //
        // To avoid these issues, the we use `useDeferredValue`: if it gets
        // another update when processing one, React will restart the background
        // rerender from scratch.

        let items: FileListItem[] = [];

        if (header) items.push(asFullSpanListItem(header));

        const { isSmallerLayout, columns } = layoutParams;
        const fileItemHeight = layoutParams.itemHeight + layoutParams.gap;
        if (disableGrouping) {
            let listItemIndex = columns;
            for (const [index, af] of annotatedFiles.entries()) {
                if (listItemIndex < columns) {
                    items[items.length - 1]!.items!.push(af);
                    listItemIndex++;
                } else {
                    listItemIndex = 1;
                    items.push({
                        height: fileItemHeight,
                        tag: "file",
                        items: [af],
                        itemStartIndex: index,
                    });
                }
            }
        } else {
            let listItemIndex = 0;
            let lastCreationTime: number | undefined;
            for (const [index, af] of annotatedFiles.entries()) {
                const creationTime = fileCreationTime(af.file) / 1000;
                if (
                    !lastCreationTime ||
                    !isSameDay(
                        new Date(creationTime),
                        new Date(lastCreationTime),
                    )
                ) {
                    lastCreationTime = creationTime;

                    items.push({
                        height: dateContainerHeight,
                        tag: "date",
                        date: af.timelineDateString,
                    });
                    items.push({
                        height: fileItemHeight,
                        tag: "file",
                        items: [af],
                        itemStartIndex: index,
                    });
                    listItemIndex = 1;
                } else if (listItemIndex < columns) {
                    items[items.length - 1]!.items!.push(af);
                    listItemIndex++;
                } else {
                    listItemIndex = 1;
                    items.push({
                        height: fileItemHeight,
                        tag: "file",
                        items: [af],
                        itemStartIndex: index,
                    });
                }
            }
        }

        if (!isSmallerLayout) {
            items = mergeTimeStampList(items, columns);
        }

        if (items.length == 1) {
            items.push({
                height: height - 48,
                component: (
                    <NoFilesContainer span={columns}>
                        <Typography sx={{ color: "text.faint" }}>
                            {t("nothing_here")}
                        </Typography>
                    </NoFilesContainer>
                ),
            });
        }

        let leftoverHeight = height - (footer?.height ?? 0);
        for (const item of items) {
            leftoverHeight -= item.height;
            if (leftoverHeight <= 0) break;
        }
        if (leftoverHeight > 0) {
            items.push({ height: leftoverHeight, component: <></> });
        }

        if (footer) items.push(asFullSpanListItem(footer));

        setItems(items);
    }, [
        width,
        height,
        header,
        footer,
        annotatedFiles,
        disableGrouping,
        layoutParams,
    ]);

    useEffect(() => {
        // Refresh list
        listRef.current?.resetAfterIndex(0);
    }, [items]);

    // TODO: Too many non-null assertions

    useEffect(() => {
        const notSelectedFiles = annotatedFiles.filter(
            (af) => !selected[af.file.id],
        );

        // Get dates of files which were manually unselected.
        const unselectedDates = new Set(
            notSelectedFiles.map((af) => af.timelineDateString),
        );

        // Get files which were manually selected.
        const localSelectedFiles = annotatedFiles.filter(
            (af) => !unselectedDates.has(af.timelineDateString),
        );

        // Get dates of files which were manually selected.
        const localSelectedDates = new Set(
            localSelectedFiles.map((af) => af.timelineDateString),
        );

        setCheckedTimelineDateStrings((prev) => {
            const checked = new Set(prev);
            // Uncheck the "Select all" checkbox if any of the files on the date
            // is unselected.
            unselectedDates.forEach((date) => checked.delete(date));
            // Check the "Select all" checkbox if all of the files on a date are
            // selected.
            localSelectedDates.forEach((date) => checked.add(date));
            return checked;
        });
    }, [annotatedFiles, selected]);

    const handleSelectMulti = handleSelectCreatorMulti(
        setSelected,
        mode,
        user?.id,
        activeCollectionID,
        activePersonID,
    );

    const onChangeSelectAllCheckBox = (date: string) => {
        const next = new Set(checkedTimelineDateStrings);
        let isDateSelected: boolean;
        if (!next.has(date)) {
            next.add(date);
            isDateSelected = true;
        } else {
            next.delete(date);
            isDateSelected = false;
        }
        setCheckedTimelineDateStrings(next);

        const filesOnADay = annotatedFiles.filter(
            (item) => item.timelineDateString === date,
        ); // all files on a checked/unchecked day

        handleSelectMulti(filesOnADay.map((af) => af.file))(isDateSelected);
    };

    const handleSelect = useMemo(
        () =>
            handleSelectCreator(
                setSelected,
                mode,
                user?.id,
                activeCollectionID,
                activePersonID,
                setRangeStart,
            ),
        [setSelected, mode, user?.id, activeCollectionID, activePersonID],
    );

    const onHoverOver = (index: number) => () => {
        setCurrentHover(index);
    };

    const handleRangeSelect = (index: number) => () => {
        if (typeof rangeStart != "undefined" && rangeStart !== index) {
            const direction =
                (index - rangeStart!) / Math.abs(index - rangeStart!);
            let checked = true;
            for (
                let i = rangeStart!;
                (index - i) * direction >= 0;
                i += direction
            ) {
                checked = checked && !!selected[annotatedFiles[i]!.file.id];
            }
            for (
                let i = rangeStart!;
                (index - i) * direction > 0;
                i += direction
            ) {
                handleSelect(annotatedFiles[i]!.file)(!checked);
            }
            handleSelect(annotatedFiles[index]!.file, index)(!checked);
        }
    };

    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if (e.key == "Shift") {
                setIsShiftKeyPressed(true);
            }
        };

        const handleKeyUp = (e: KeyboardEvent) => {
            if (e.key == "Shift") {
                setIsShiftKeyPressed(false);
            }
        };

        document.addEventListener("keydown", handleKeyDown);
        document.addEventListener("keyup", handleKeyUp);

        return () => {
            document.removeEventListener("keydown", handleKeyDown);
            document.removeEventListener("keyup", handleKeyUp);
        };
    }, []);

    useEffect(() => {
        if (selected.count === 0) {
            setRangeStart(null);
        }
    }, [selected]);

    const getThumbnail = (
        { file }: FileListAnnotatedFile,
        index: number,
        isScrolling: boolean,
    ) => (
        <FileThumbnail
            key={`tile-${file.id}-selected-${selected[file.id] ?? false}`}
            {...{ user, emailByUserID }}
            file={file}
            onClick={() => onItemClick(index)}
            selectable={selectable!}
            onSelect={handleSelect(file, index)}
            selected={
                (!mode
                    ? selected.collectionID === activeCollectionID
                    : mode == selected.context?.mode &&
                      (selected.context.mode == "people"
                          ? selected.context.personID == activePersonID
                          : selected.context.collectionID ==
                            activeCollectionID)) && !!selected[file.id]
            }
            selectOnClick={selected.count > 0}
            onHover={onHoverOver(index)}
            onRangeSelect={handleRangeSelect(index)}
            isRangeSelectActive={isShiftKeyPressed && selected.count > 0}
            isInsSelectRange={
                (index >= rangeStart! && index <= currentHover!) ||
                (index >= currentHover! && index <= rangeStart!)
            }
            activeCollectionID={activeCollectionID}
            showPlaceholder={isScrolling}
            isFav={favoriteFileIDs?.has(file.id)}
        />
    );

    // eslint-disable-next-line react-hooks/exhaustive-deps
    const renderListItem = (
        listItem: FileListItem,
        isScrolling: boolean | undefined,
    ) => {
        const haveSelection = selected.count > 0;
        switch (listItem.tag) {
            case "date":
                return listItem.dates ? (
                    listItem.dates
                        .map((item) => [
                            <DateContainer key={item.date} span={item.span}>
                                {haveSelection && (
                                    <Checkbox
                                        key={item.date}
                                        name={item.date}
                                        checked={checkedTimelineDateStrings.has(
                                            item.date,
                                        )}
                                        onChange={() =>
                                            onChangeSelectAllCheckBox(item.date)
                                        }
                                        size="small"
                                        sx={{ pl: 0 }}
                                    />
                                )}
                                {item.date}
                            </DateContainer>,
                            <div key={`${item.date}-gap`} />,
                        ])
                        .flat()
                ) : (
                    <DateContainer span={columns}>
                        {haveSelection && (
                            <Checkbox
                                key={listItem.date}
                                name={listItem.date!}
                                checked={checkedTimelineDateStrings.has(
                                    listItem.date,
                                )}
                                onChange={() =>
                                    onChangeSelectAllCheckBox(listItem.date!)
                                }
                                size="small"
                                sx={{ pl: 0 }}
                            />
                        )}
                        {listItem.date}
                    </DateContainer>
                );
            case "file": {
                const ret = listItem.items!.map((item, idx) =>
                    getThumbnail(
                        item,
                        listItem.itemStartIndex! + idx,
                        !!isScrolling,
                    ),
                );
                if (listItem.groups) {
                    let sum = 0;
                    for (let i = 0; i < listItem.groups.length - 1; i++) {
                        sum = sum + listItem.groups[i]!;
                        ret.splice(
                            sum,
                            0,
                            <div
                                key={`${listItem.items![0]!.file.id}-gap-${i}`}
                            />,
                        );
                        sum += 1;
                    }
                }
                return ret;
            }
            default:
                return listItem.component;
        }
    };

    const itemData = useMemo(
        () => ({ items, layoutParams, renderListItem }),
        [items, layoutParams, renderListItem],
    );

    const itemSize = useCallback(
        (index: number) => itemData.items[index]!.height,
        [itemData],
    );

    const itemKey = useCallback((index: number, itemData: FileListItemData) => {
        const item = itemData.items[index]!;
        switch (item.tag) {
            case "date":
                return `${item.date ?? ""}-${index}`;
            case "file":
                return `${item.items![0]!.file.id}-${
                    item.items!.slice(-1)[0]!.file.id
                }`;
            default:
                return `${index}`;
        }
    }, []);

    if (!items.length) {
        return <></>;
    }

    // The old, mode unaware, behaviour.
    let key = `${activeCollectionID}`;
    if (modePlus) {
        // If the new experimental modePlus prop is provided, use it to derive a
        // mode specific key.
        if (modePlus == "search") {
            key = "search";
        } else if (modePlus == "people") {
            if (!activePersonID) {
                assertionFailed();
            } else {
                key = activePersonID;
            }
        }
    }

    return (
        <VariableSizeList
            key={key}
            ref={listRef}
            {...{ width, height, itemData, itemSize, itemKey }}
            itemCount={items.length}
            overscanCount={3}
            useIsScrolling
        >
            {FileListRow}
        </VariableSizeList>
    );
};

/**
 * Checks and merge multiple dates into a single row.
 */
const mergeTimeStampList = (
    items: FileListItem[],
    columns: number,
): FileListItem[] => {
    const newList: FileListItem[] = [];
    let index = 0;
    let newIndex = 0;
    while (index < items.length) {
        const currItem = items[index]!;
        // If the current item is of type time, then it is not part of an ongoing date.
        // So, there is a possibility of merge.
        if (currItem.tag == "date") {
            // If new list pointer is not at the end of list then
            // we can add more items to the same list.
            if (newList[newIndex]) {
                const SPACE_BTW_DATES_TO_IMAGE_CONTAINER_WIDTH_RATIO = 0.244;
                // Check if items can be added to same list
                if (
                    newList[newIndex + 1]!.items!.length +
                        items[index + 1]!.items!.length +
                        Math.ceil(
                            newList[newIndex]!.dates!.length *
                                SPACE_BTW_DATES_TO_IMAGE_CONTAINER_WIDTH_RATIO,
                        ) <=
                    columns
                ) {
                    newList[newIndex]!.dates!.push({
                        date: currItem.date!,
                        span: items[index + 1]!.items!.length,
                    });
                    newList[newIndex + 1]!.items = [
                        ...newList[newIndex + 1]!.items!,
                        ...items[index + 1]!.items!,
                    ];
                    index += 2;
                } else {
                    // Adding items would exceed the number of columns.
                    // So, move new list pointer to the end. Hence, in next iteration,
                    // items will be added to a new list.
                    newIndex += 2;
                }
            } else {
                // New list pointer was at the end of list so simply add new items to the list.
                newList.push({
                    ...currItem,
                    date: null,
                    dates: [
                        {
                            date: currItem.date!,
                            span: items[index + 1]!.items!.length,
                        },
                    ],
                });
                newList.push(items[index + 1]!);
                index += 2;
            }
        } else {
            // Merge cannot happen. Simply add all items to new list
            // and set new list point to the end of list.
            newList.push(currItem);
            index++;
            newIndex = newList.length;
        }
    }
    for (let i = 0; i < newList.length; i++) {
        const currItem = newList[i]!;
        const nextItem = newList[i + 1]!;
        if (currItem.tag == "date") {
            if (currItem.dates!.length > 1) {
                currItem.groups = currItem.dates!.map((item) => item.span);
                nextItem.groups = currItem.groups;
            }
        }
    }
    return newList;
};

/**
 * An grid item, spanning {@link span} columns.
 */
const ListItemContainer = styled("div")<{ span: number }>`
    grid-column: span ${({ span }) => span};
    display: flex;
    align-items: center;
`;

/**
 * A grid items that spans all columns.
 */
const FullSpanListItemContainer = styled("div")`
    // grid-column: 1 / -1;
    display: flex;
    align-items: center;
`;

/**
 * Convert a {@link FileListHeaderOrFooter} into a {@link FileListItem}
 * that spans all columns.
 */
const asFullSpanListItem = ({
    component,
    ...rest
}: FileListHeaderOrFooter) => ({
    ...rest,
    tag: "span",
    component: (
        <FullSpanListItemContainer>{component}</FullSpanListItemContainer>
    ),
});

/**
 * The fixed height (in px) of {@link DateContainer}.
 */
const dateContainerHeight = 48;

const DateContainer = styled(ListItemContainer)(
    ({ theme }) => `
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    height: ${dateContainerHeight}px;
    color: ${theme.vars.palette.text.muted};
`,
);

const NoFilesContainer = styled(ListItemContainer)`
    text-align: center;
    justify-content: center;
`;

interface FileListItemData {
    items: FileListItem[];
    layoutParams: ThumbnailGridLayoutParams;
    renderListItem: (
        timeStampListItem: FileListItem,
        isScrolling?: boolean,
    ) => React.JSX.Element;
}

const FileListRow = memo(
    ({
        index,
        style,
        isScrolling,
        data,
    }: ListChildComponentProps<FileListItemData>) => {
        const { items, layoutParams, renderListItem } = data;
        const { columns, itemWidth, paddingInline, gap } = layoutParams;

        const item = items[index]!;
        const { groups } = item;

        const gridTemplateColumns = groups
            ? groups.map((x) => `repeat(${x}, ${itemWidth}px)`).join(" 44px ")
            : `repeat(${columns}, ${itemWidth}px)`;
        const px = item.extendToInlineEdges ? 0 : paddingInline;

        if (item.tag == "span") {
            return (
                <Box
                    style={style}
                    sx={{ width: "100%", paddingInline: `${px}px` }}
                >
                    {renderListItem(item, isScrolling)}
                </Box>
            );
        }
        return (
            <Box
                style={style}
                sx={{
                    display: "grid",
                    gridTemplateColumns,
                    columnGap: `${gap}px`,
                    width: "100%",
                    paddingInline: `${px}px`,
                }}
            >
                {renderListItem(item, isScrolling)}
            </Box>
        );
    },
    areEqual,
);

type FileThumbnailProps = {
    file: EnteFile;
    onClick: () => void;
    selectable: boolean;
    selected: boolean;
    onSelect: (checked: boolean) => void;
    onHover: () => void;
    onRangeSelect: () => void;
    isRangeSelectActive: boolean;
    selectOnClick: boolean;
    isInsSelectRange: boolean;
    activeCollectionID: number;
    showPlaceholder: boolean;
    isFav: boolean | undefined;
} & Pick<FileListProps, "user" | "emailByUserID">;

const FileThumbnail: React.FC<FileThumbnailProps> = ({
    file,
    user,
    onClick,
    selectable,
    selected,
    onSelect,
    selectOnClick,
    onHover,
    onRangeSelect,
    isRangeSelectActive,
    isInsSelectRange,
    isFav,
    emailByUserID,
    activeCollectionID,
    showPlaceholder,
}) => {
    const [imageURL, setImageURL] = useState<string | undefined>(undefined);
    const [isLongPressing, setIsLongPressing] = useState(false);

    const longPressHandlers = useMemo(
        () => ({
            onMouseDown: () => setIsLongPressing(true),
            onMouseUp: () => setIsLongPressing(false),
            onMouseLeave: () => setIsLongPressing(false),
            onTouchStart: () => setIsLongPressing(true),
            onTouchEnd: () => setIsLongPressing(false),
        }),
        [],
    );

    useEffect(() => {
        const timerID = isLongPressing
            ? setTimeout(() => onSelect(!selected), 500)
            : undefined;
        return () => {
            if (timerID) clearTimeout(timerID);
        };
    }, [selected, onSelect, isLongPressing]);

    useEffect(() => {
        let didCancel = false;

        void downloadManager
            .renderableThumbnailURL(file, showPlaceholder)
            .then((url) => !didCancel && setImageURL(url))
            .catch((e: unknown) => {
                log.warn("Failed to fetch thumbnail", e);
            });

        return () => {
            didCancel = true;
        };
    }, [file, showPlaceholder]);

    const handleClick = () => {
        if (selectOnClick) {
            if (isRangeSelectActive) {
                onRangeSelect();
            } else {
                onSelect(!selected);
            }
        } else if (imageURL) {
            onClick();
        }
    };

    const handleSelect: React.ChangeEventHandler<HTMLInputElement> = (e) => {
        if (isRangeSelectActive) {
            onRangeSelect();
        } else {
            onSelect(e.target.checked);
        }
    };

    const handleHover = () => {
        if (isRangeSelectActive) {
            onHover();
        }
    };

    // See: [Note: Files in trash pseudo collection have deleteBy]
    const deleteBy =
        activeCollectionID == PseudoCollectionID.trash &&
        (file as EnteTrashFile).deleteBy;

    return (
        <FileThumbnail_
            key={`thumb-${file.id}}`}
            onClick={handleClick}
            onMouseEnter={handleHover}
            disabled={!imageURL}
            {...(selectable && longPressHandlers)}
        >
            {selectable && (
                <Check
                    type="checkbox"
                    checked={selected}
                    onChange={handleSelect}
                    $active={isRangeSelectActive && isInsSelectRange}
                    onClick={(e) => e.stopPropagation()}
                />
            )}
            {file.metadata.hasStaticThumbnail ? (
                <StaticThumbnail fileType={file.metadata.fileType} />
            ) : imageURL ? (
                <img src={imageURL} />
            ) : (
                <LoadingThumbnail />
            )}
            {file.metadata.fileType == FileType.livePhoto ? (
                <FileTypeIndicatorOverlay>
                    <AlbumOutlinedIcon fontSize="small" />
                </FileTypeIndicatorOverlay>
            ) : (
                file.metadata.fileType == FileType.video && (
                    <VideoDurationOverlay duration={fileDurationString(file)} />
                )
            )}
            {selected && <SelectedOverlay />}
            {shouldShowAvatar(file, user) && (
                <AvatarOverlay>
                    <Avatar {...{ user, file, emailByUserID }} />
                </AvatarOverlay>
            )}
            {isFav && (
                <FavoriteOverlay>
                    <FavoriteRoundedIcon />
                </FavoriteOverlay>
            )}

            <HoverOverlay
                className="preview-card-hover-overlay"
                checked={selected}
            />
            {isRangeSelectActive && isInsSelectRange && (
                <InSelectRangeOverlay />
            )}

            {deleteBy && (
                <TileBottomTextOverlay>
                    <Typography variant="small">
                        {formattedDateRelative(deleteBy)}
                    </Typography>
                </TileBottomTextOverlay>
            )}
        </FileThumbnail_>
    );
};

const FileThumbnail_ = styled("div")<{ disabled: boolean }>`
    display: flex;
    width: fit-content;
    margin-bottom: ${GAP_BTW_TILES}px;
    min-width: 100%;
    overflow: hidden;
    position: relative;
    flex: 1;
    cursor: ${(props) => (props.disabled ? "not-allowed" : "pointer")};
    user-select: none;
    & > img {
        object-fit: cover;
        max-width: 100%;
        min-height: 100%;
        flex: 1;
        pointer-events: none;
    }

    &:hover {
        input[type="checkbox"] {
            visibility: visible;
            opacity: 0.5;
        }

        .preview-card-hover-overlay {
            opacity: 1;
        }
    }

    border-radius: 4px;
`;

const Check = styled("input")<{ $active: boolean }>(
    ({ theme, $active }) => `
    appearance: none;
    position: absolute;
    /* Increase z-index in stacking order to capture clicks */
    z-index: 1;
    left: 0;
    outline: none;
    cursor: pointer;
    @media (pointer: coarse) {
        pointer-events: none;
    }

    &::before {
        content: "";
        width: 19px;
        height: 19px;
        background-color: #ddd;
        display: inline-block;
        border-radius: 50%;
        vertical-align: bottom;
        margin: 6px 6px;
        transition: background-color 0.3s ease;
        pointer-events: inherit;

    }
    &::after {
        content: "";
        position: absolute;
        width: 5px;
        height: 11px;
        border-right: 2px solid #333;
        border-bottom: 2px solid #333;
        transition: transform 0.3s ease;
        pointer-events: inherit;
        transform: translate(-18px, 9px) rotate(45deg);
    }

    /* checkmark background (filled circle) */
    &:checked::before {
        content: "";
        background-color: ${theme.vars.palette.accent.main};
        border-color: ${theme.vars.palette.accent.main};
        color: white;
    }
    /* checkmark foreground (tick) */
    &:checked::after {
        content: "";
        border-right: 2px solid #ddd;
        border-bottom: 2px solid #ddd;
    }
    visibility: hidden;
    ${$active && "visibility: visible; opacity: 0.5;"};
    &:checked {
        visibility: visible;
        opacity: 1 !important;
    }
`,
);

const HoverOverlay = styled("div")<{ checked: boolean }>`
    opacity: 0;
    left: 0;
    top: 0;
    outline: none;
    height: 40%;
    width: 100%;
    position: absolute;
    ${(props) =>
        !props.checked &&
        "background:linear-gradient(rgba(0, 0, 0, 0.2), rgba(0, 0, 0, 0))"};
`;

/**
 * An overlay showing the avatars of the person who shared the item, at the top
 * right.
 */
const AvatarOverlay = styled(Overlay)`
    display: flex;
    justify-content: flex-end;
    align-items: flex-start;
    padding: 5px;
`;

/**
 * An overlay showing the favorite icon at bottom left.
 */
const FavoriteOverlay = styled(Overlay)`
    display: flex;
    justify-content: flex-start;
    align-items: flex-end;
    padding: 5px;
    color: white;
    opacity: 0.6;
`;

/**
 * An overlay with a gradient, showing the file type indicator (e.g. live photo,
 * video) at the bottom right.
 */
const FileTypeIndicatorOverlay = styled(Overlay)`
    display: flex;
    justify-content: flex-end;
    align-items: flex-end;
    padding: 5px;
    color: white;
    background: linear-gradient(
        315deg,
        rgba(0 0 0 / 0.14) 0%,
        rgba(0 0 0 / 0.05) 30%,
        transparent 50%
    );
`;

const InSelectRangeOverlay = styled(Overlay)(
    ({ theme }) => `
    outline: none;
    background: ${theme.vars.palette.accent.main};
    opacity: 0.14;
`,
);

const SelectedOverlay = styled(Overlay)(
    ({ theme }) => `
    border: 2px solid ${theme.vars.palette.accent.main};
    border-radius: 4px;
`,
);

interface VideoDurationOverlayProps {
    duration: string | undefined;
}

const VideoDurationOverlay: React.FC<VideoDurationOverlayProps> = ({
    duration,
}) => (
    <FileTypeIndicatorOverlay>
        {duration ? (
            <Typography variant="mini">{duration}</Typography>
        ) : (
            <PlayCircleOutlineOutlinedIcon fontSize="small" />
        )}
    </FileTypeIndicatorOverlay>
);

/**
 * Return `true` if the owner or uploader name avatar indicator should be shown
 * for the given {@link file}.
 */
const shouldShowAvatar = (file: EnteFile, user: LocalUser | undefined) => {
    // Public albums app.
    if (!user) return false;
    // A file shared with the user.
    if (file.ownerID != user.id) return true;
    // A public collected file (i.e. a file owned by the user, uploaded by an
    // named guest via a public collect link)
    if (file.pubMagicMetadata?.data.uploaderName) return true;
    // Regular file.
    return false;
};
