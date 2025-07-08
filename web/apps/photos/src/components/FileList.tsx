// TODO: Audit this file
/* eslint-disable @typescript-eslint/restrict-plus-operands */
import AlbumOutlinedIcon from "@mui/icons-material/AlbumOutlined";
import FavoriteRoundedIcon from "@mui/icons-material/FavoriteRounded";
import PlayCircleOutlineOutlinedIcon from "@mui/icons-material/PlayCircleOutlineOutlined";
import { Box, Checkbox, Link, Typography, styled } from "@mui/material";
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
import {
    GAP_BTW_TILES,
    IMAGE_CONTAINER_MAX_HEIGHT,
    IMAGE_CONTAINER_MAX_WIDTH,
    MIN_COLUMNS,
} from "ente-new/photos/components/FileList";
import type { GalleryBarMode } from "ente-new/photos/components/gallery/reducer";
import {
    LoadingThumbnail,
    StaticThumbnail,
} from "ente-new/photos/components/PlaceholderThumbnails";
import { TileBottomTextOverlay } from "ente-new/photos/components/Tiles";
import { PseudoCollectionID } from "ente-new/photos/services/collection-summary";
import { t } from "i18next";
import memoize from "memoize-one";
import React, { useContext, useEffect, useMemo, useRef, useState } from "react";
import { Trans } from "react-i18next";
import {
    VariableSizeList as List,
    type ListChildComponentProps,
    areEqual,
} from "react-window";
import { type SelectedState, shouldShowAvatar } from "utils/file";
import {
    handleSelectCreator,
    handleSelectCreatorMulti,
} from "utils/photoFrame";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";

export const DATE_CONTAINER_HEIGHT = 48;
export const SPACE_BTW_DATES = 44;

const SPACE_BTW_DATES_TO_IMAGE_CONTAINER_WIDTH_RATIO = 0.244;

const FOOTER_HEIGHT = 90;
const ALBUM_FOOTER_HEIGHT = 75;
const ALBUM_FOOTER_HEIGHT_WITH_REFERRAL = 113;

/**
 * A component with an explicit height suitable for being plugged in as the
 * {@link header} or {@link footer} of the {@link FileList}.
 */
export interface FileListHeaderOrFooter {
    /**
     * The component itself.
     */
    item: React.ReactNode;
    /**
     * The height of the component (in px).
     */
    height: number;
}

interface TimeStampListItem {
    /**
     * An optional {@link FileListItemTag} that can be used to identify item
     * types for conditional behaviour.
     */
    tag?: "date" | "file";
    items?: FileListAnnotatedFile[];
    itemStartIndex?: number;
    date?: string;
    dates?: { date: string; span: number }[];
    groups?: number[];
    item?: any;
    id?: string;
    height?: number;
    fileSize?: number;
    fileCount?: number;
}

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
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext,
    );

    const [timeStampList, setTimeStampList] = useState<TimeStampListItem[]>([]);
    const refreshInProgress = useRef(false);
    const shouldRefresh = useRef(false);
    const listRef = useRef(null);

    // Timeline date strings for which all photos have been selected.
    //
    // See: [Note: Timeline date string]
    const [checkedTimelineDateStrings, setCheckedTimelineDateStrings] =
        useState(new Set());

    const [rangeStart, setRangeStart] = useState(null);
    const [currentHover, setCurrentHover] = useState(null);
    const [isShiftKeyPressed, setIsShiftKeyPressed] = useState(false);

    const fittableColumns = getFractionFittableColumns(width);
    let columns = Math.floor(fittableColumns);

    let skipMerge = false;
    if (columns < MIN_COLUMNS) {
        columns = MIN_COLUMNS;
        skipMerge = true;
    }
    const shrinkRatio = getShrinkRatio(width, columns);
    const listItemHeight =
        IMAGE_CONTAINER_MAX_HEIGHT * shrinkRatio + GAP_BTW_TILES;

    const refreshList = () => {
        listRef.current?.resetAfterIndex(0);
    };

    useEffect(() => {
        const main = () => {
            if (refreshInProgress.current) {
                shouldRefresh.current = true;
                return;
            }
            refreshInProgress.current = true;
            let timeStampList: TimeStampListItem[] = [];

            if (header) {
                timeStampList.push(asFullSpanListItem(header));
            }
            if (disableGrouping) {
                noGrouping(timeStampList);
            } else {
                groupByTime(timeStampList);
            }

            if (!skipMerge) {
                timeStampList = mergeTimeStampList(timeStampList, columns);
            }
            if (timeStampList.length === 1) {
                timeStampList.push(getEmptyListItem());
            }
            timeStampList.push(getVacuumItem(timeStampList));
            if (footer) {
                timeStampList.push(asFullSpanListItem(footer));
            }

            if (publicCollectionGalleryContext.credentials) {
                timeStampList.push(getAlbumsFooter());
            }

            setTimeStampList(timeStampList);
            refreshInProgress.current = false;
            if (shouldRefresh.current) {
                shouldRefresh.current = false;
                setTimeout(main, 0);
            }
        };
        main();
    }, [
        width,
        height,
        annotatedFiles,
        header,
        footer,
        disableGrouping,
        publicCollectionGalleryContext.credentials,
    ]);

    useEffect(() => {
        refreshList();
    }, [timeStampList]);

    const groupByTime = (timeStampList: TimeStampListItem[]) => {
        let listItemIndex = 0;
        let lastCreationTime: number | undefined;
        annotatedFiles.forEach((item, index) => {
            const creationTime = fileCreationTime(item.file) / 1000;
            if (
                !lastCreationTime ||
                !isSameDay(new Date(creationTime), new Date(lastCreationTime))
            ) {
                lastCreationTime = creationTime;

                timeStampList.push({
                    tag: "date",
                    date: item.timelineDateString,
                    id: lastCreationTime.toString(),
                });
                timeStampList.push({
                    tag: "file",
                    items: [item],
                    itemStartIndex: index,
                });
                listItemIndex = 1;
            } else if (listItemIndex < columns) {
                timeStampList[timeStampList.length - 1].items.push(item);
                listItemIndex++;
            } else {
                listItemIndex = 1;
                timeStampList.push({
                    tag: "file",
                    items: [item],
                    itemStartIndex: index,
                });
            }
        });
    };

    const noGrouping = (timeStampList: TimeStampListItem[]) => {
        let listItemIndex = columns;
        annotatedFiles.forEach((item, index) => {
            if (listItemIndex < columns) {
                timeStampList[timeStampList.length - 1].items.push(item);
                listItemIndex++;
            } else {
                listItemIndex = 1;
                timeStampList.push({
                    tag: "file",
                    items: [item],
                    itemStartIndex: index,
                });
            }
        });
    };

    const getEmptyListItem = () => {
        return {
            item: (
                <NothingContainer span={columns}>
                    <Typography sx={{ color: "text.faint" }}>
                        {t("nothing_here")}
                    </Typography>
                </NothingContainer>
            ),
            id: "empty-list-banner",
            height: height - 48,
        };
    };

    const getVacuumItem = (timeStampList) => {
        let footerHeight;
        if (publicCollectionGalleryContext.credentials) {
            footerHeight = publicCollectionGalleryContext.referralCode
                ? ALBUM_FOOTER_HEIGHT_WITH_REFERRAL
                : ALBUM_FOOTER_HEIGHT;
        } else {
            footerHeight = FOOTER_HEIGHT;
        }
        const fileListHeight = (() => {
            let sum = 0;
            const getCurrentItemSize = getItemSize(timeStampList);
            for (let i = 0; i < timeStampList.length; i++) {
                sum += getCurrentItemSize(i);
                if (height - sum <= footerHeight) {
                    break;
                }
            }
            return sum;
        })();
        return {
            item: <></>,
            height: Math.max(height - fileListHeight - footerHeight, 0),
        };
    };

    const getAlbumsFooter = (): TimeStampListItem => ({
        height: publicCollectionGalleryContext.referralCode
            ? ALBUM_FOOTER_HEIGHT_WITH_REFERRAL
            : ALBUM_FOOTER_HEIGHT,
        item: (
            <AlbumFooterContainer
                span={columns}
                hasReferral={!!publicCollectionGalleryContext.referralCode}
            >
                {/* Make the entire area tappable, otherwise it is hard to
                    get at on mobile devices. */}
                <Box sx={{ width: "100%" }}>
                    <Link
                        color="text.base"
                        sx={{ "&:hover": { color: "inherit" } }}
                        target="_blank"
                        href={"https://ente.io"}
                    >
                        <Typography variant="small">
                            <Trans
                                i18nKey="shared_using"
                                components={{
                                    a: (
                                        <Typography
                                            variant="small"
                                            component="span"
                                            sx={{ color: "accent.main" }}
                                        />
                                    ),
                                }}
                                values={{ url: "ente.io" }}
                            />
                        </Typography>
                    </Link>
                    {publicCollectionGalleryContext.referralCode ? (
                        <FullStretchContainer>
                            <Typography
                                sx={{
                                    marginTop: "12px",
                                    padding: "8px",
                                    color: "accent.contrastText",
                                }}
                            >
                                <Trans
                                    i18nKey={"sharing_referral_code"}
                                    values={{
                                        referralCode:
                                            publicCollectionGalleryContext.referralCode,
                                    }}
                                />
                            </Typography>
                        </FullStretchContainer>
                    ) : null}
                </Box>
            </AlbumFooterContainer>
        ),
    });

    /**
     * Checks and merge multiple dates into a single row.
     */
    const mergeTimeStampList = (
        items: TimeStampListItem[],
        columns: number,
    ): TimeStampListItem[] => {
        const newList: TimeStampListItem[] = [];
        let index = 0;
        let newIndex = 0;
        while (index < items.length) {
            const currItem = items[index];
            // If the current item is of type time, then it is not part of an ongoing date.
            // So, there is a possibility of merge.
            if (currItem.tag == "date") {
                // If new list pointer is not at the end of list then
                // we can add more items to the same list.
                if (newList[newIndex]) {
                    // Check if items can be added to same list
                    if (
                        newList[newIndex + 1].items.length +
                            items[index + 1].items.length +
                            Math.ceil(
                                newList[newIndex].dates.length *
                                    SPACE_BTW_DATES_TO_IMAGE_CONTAINER_WIDTH_RATIO,
                            ) <=
                        columns
                    ) {
                        newList[newIndex].dates.push({
                            date: currItem.date,
                            span: items[index + 1].items.length,
                        });
                        newList[newIndex + 1].items = [
                            ...newList[newIndex + 1].items,
                            ...items[index + 1].items,
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
                                date: currItem.date,
                                span: items[index + 1].items.length,
                            },
                        ],
                    });
                    newList.push(items[index + 1]);
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
            const currItem = newList[i];
            const nextItem = newList[i + 1];
            if (currItem.tag == "date") {
                if (currItem.dates.length > 1) {
                    currItem.groups = currItem.dates.map((item) => item.span);
                    nextItem.groups = currItem.groups;
                }
            }
        }
        return newList;
    };

    const getItemSize = (timeStampList) => (index) => {
        switch (timeStampList[index].tag) {
            case "date":
                return DATE_CONTAINER_HEIGHT;
            case "file":
                return listItemHeight;
            default:
                return timeStampList[index].height;
        }
    };

    const generateKey = (index) => {
        switch (timeStampList[index].tag) {
            case "file":
                return `${timeStampList[index].items[0].file.id}-${
                    timeStampList[index].items.slice(-1)[0].file.id
                }`;
            default:
                return `${timeStampList[index].id}-${index}`;
        }
    };

    useEffect(() => {
        // Nothing to do here if nothing is selected.
        if (!selected) return;

        const notSelectedFiles = (annotatedFiles ?? []).filter(
            (item) => !selected[item.file.id],
        );

        const unselectedDates = new Set(
            notSelectedFiles.map((item) => item.timelineDateString),
        ); // to get file's date which were manually unselected

        const localSelectedFiles = (annotatedFiles ?? []).filter(
            // to get files which were manually selected
            (item) => !unselectedDates.has(item.timelineDateString),
        );

        const localSelectedDates = new Set(
            localSelectedFiles.map((item) => item.timelineDateString),
        ); // to get file's date which were manually selected

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
    }, [selected]);

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

        const filesOnADay = annotatedFiles?.filter(
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
                (index - rangeStart) / Math.abs(index - rangeStart);
            let checked = true;
            for (
                let i = rangeStart;
                (index - i) * direction >= 0;
                i += direction
            ) {
                checked = checked && !!selected[annotatedFiles[i].file.id];
            }
            for (
                let i = rangeStart;
                (index - i) * direction > 0;
                i += direction
            ) {
                handleSelect(annotatedFiles[i].file)(!checked);
            }
            handleSelect(annotatedFiles[index].file, index)(!checked);
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
            selectable={selectable}
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
                (index >= rangeStart && index <= currentHover) ||
                (index >= currentHover && index <= rangeStart)
            }
            activeCollectionID={activeCollectionID}
            showPlaceholder={isScrolling}
            isFav={favoriteFileIDs?.has(file.id)}
        />
    );

    const renderListItem = (
        listItem: TimeStampListItem,
        isScrolling: boolean,
    ) => {
        const haveSelection = (selected.count ?? 0) > 0;
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
                                name={listItem.date}
                                checked={checkedTimelineDateStrings.has(
                                    listItem.date,
                                )}
                                onChange={() =>
                                    onChangeSelectAllCheckBox(listItem.date)
                                }
                                size="small"
                                sx={{ pl: 0 }}
                            />
                        )}
                        {listItem.date}
                    </DateContainer>
                );
            case "file": {
                const ret = listItem.items.map((item, idx) =>
                    getThumbnail(
                        item,
                        listItem.itemStartIndex + idx,
                        isScrolling,
                    ),
                );
                if (listItem.groups) {
                    let sum = 0;
                    for (let i = 0; i < listItem.groups.length - 1; i++) {
                        sum = sum + listItem.groups[i];
                        ret.splice(
                            sum,
                            0,
                            <div
                                key={`${listItem.items[0].file.id}-gap-${i}`}
                            />,
                        );
                        sum += 1;
                    }
                }
                return ret;
            }
            default:
                return listItem.item;
        }
    };

    if (!timeStampList?.length) {
        return <></>;
    }

    const itemData = createItemData(
        timeStampList,
        columns,
        shrinkRatio,
        renderListItem,
    );

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
        <List
            key={key}
            itemData={itemData}
            ref={listRef}
            itemSize={getItemSize(timeStampList)}
            height={height}
            width={width}
            itemCount={timeStampList.length}
            itemKey={generateKey}
            overscanCount={3}
            useIsScrolling
        >
            {PhotoListRow}
        </List>
    );
};

const ListItem = styled("div")`
    display: flex;
    justify-content: center;
`;

const getTemplateColumns = (
    columns: number,
    shrinkRatio: number,
    groups?: number[],
): string => {
    if (groups) {
        // need to confirm why this was there
        // const sum = groups.reduce((acc, item) => acc + item, 0);
        // if (sum < columns) {
        //     groups[groups.length - 1] += columns - sum;
        // }
        return groups
            .map(
                (x) =>
                    `repeat(${x}, ${IMAGE_CONTAINER_MAX_WIDTH * shrinkRatio}px)`,
            )
            .join(` ${SPACE_BTW_DATES}px `);
    } else {
        return `repeat(${columns},${
            IMAGE_CONTAINER_MAX_WIDTH * shrinkRatio
        }px)`;
    }
};

function getFractionFittableColumns(width: number): number {
    return (
        (width - 2 * getGapFromScreenEdge(width) + GAP_BTW_TILES) /
        (IMAGE_CONTAINER_MAX_WIDTH + GAP_BTW_TILES)
    );
}

function getGapFromScreenEdge(width: number) {
    if (width > MIN_COLUMNS * IMAGE_CONTAINER_MAX_WIDTH) {
        return 24;
    } else {
        return 4;
    }
}

function getShrinkRatio(width: number, columns: number) {
    return (
        (width -
            2 * getGapFromScreenEdge(width) -
            (columns - 1) * GAP_BTW_TILES) /
        (columns * IMAGE_CONTAINER_MAX_WIDTH)
    );
}

const ListContainer = styled(Box, {
    shouldForwardProp: (propName) => propName != "gridTemplateColumns",
})<{ gridTemplateColumns: string }>`
    display: grid;
    grid-template-columns: ${(props) => props.gridTemplateColumns};
    grid-column-gap: ${GAP_BTW_TILES}px;
    width: 100%;
    padding: 0 24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * MIN_COLUMNS}px) {
        padding: 0 4px;
    }
`;

const ListItemContainer = styled("div")<{ span: number }>`
    grid-column: span ${(props) => props.span};
    display: flex;
    align-items: center;
`;

const FullSpanListItemContainer = styled("div")`
    grid-column: 1 / -1;
    display: flex;
    align-items: center;
`;

const asFullSpanListItem = ({ item, ...rest }: TimeStampListItem) => ({
    ...rest,
    item: <FullSpanListItemContainer>{item}</FullSpanListItemContainer>,
});

const DateContainer = styled(ListItemContainer)(
    ({ theme }) => `
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    height: ${DATE_CONTAINER_HEIGHT}px;
    color: ${theme.vars.palette.text.muted};
`,
);

const AlbumFooterContainer = styled(ListItemContainer, {
    shouldForwardProp: (propName) => propName != "hasReferral",
})<{ hasReferral: boolean }>`
    margin-top: 48px;
    margin-bottom: ${({ hasReferral }) => (!hasReferral ? `10px` : "0px")};
    text-align: center;
    justify-content: center;
`;

const FullStretchContainer = styled("div")(
    ({ theme }) => `
    margin: 0 -24px;
    width: calc(100% + 46px);
    left: -24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * MIN_COLUMNS}px) {
        margin: 0 -4px;
        width: calc(100% + 6px);
        left: -4px;
    }
    background-color: ${theme.vars.palette.accent.main};
`,
);

const NothingContainer = styled(ListItemContainer)`
    text-align: center;
    justify-content: center;
`;

interface ItemData {
    timeStampList: TimeStampListItem[];
    columns: number;
    shrinkRatio: number;
    renderListItem: (
        timeStampListItem: TimeStampListItem,
        isScrolling?: boolean,
    ) => React.JSX.Element;
}

const createItemData = memoize(
    (
        timeStampList: TimeStampListItem[],
        columns: number,
        shrinkRatio: number,
        renderListItem: (
            timeStampListItem: TimeStampListItem,
            isScrolling?: boolean,
        ) => React.JSX.Element,
    ): ItemData => ({ timeStampList, columns, shrinkRatio, renderListItem }),
);

const PhotoListRow = React.memo(
    ({
        index,
        style,
        isScrolling,
        data,
    }: ListChildComponentProps<ItemData>) => {
        const { timeStampList, columns, shrinkRatio, renderListItem } = data;
        return (
            <ListItem style={style}>
                <ListContainer
                    gridTemplateColumns={getTemplateColumns(
                        columns,
                        shrinkRatio,
                        timeStampList[index].groups,
                    )}
                >
                    {renderListItem(timeStampList[index], isScrolling)}
                </ListContainer>
            </ListItem>
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
    isFav: boolean;
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
            onClick?.();
        }
    };

    const handleSelect: React.ChangeEventHandler<HTMLInputElement> = (e) => {
        if (isRangeSelectActive) {
            onRangeSelect?.();
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
