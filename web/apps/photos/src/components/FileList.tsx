import { assertionFailed } from "@/base/assert";
import { isSameDay } from "@/base/date";
import { EnteFile } from "@/media/file";
import {
    GAP_BTW_TILES,
    IMAGE_CONTAINER_MAX_HEIGHT,
    IMAGE_CONTAINER_MAX_WIDTH,
    MIN_COLUMNS,
} from "@/new/photos/components/FileList";
import { FlexWrapper } from "@ente/shared/components/Container";
import { Box, Checkbox, Link, Typography, styled } from "@mui/material";
import type { PhotoFrameProps } from "components/PhotoFrame";
import { t } from "i18next";
import memoize from "memoize-one";
import { GalleryContext } from "pages/gallery";
import React, { useContext, useEffect, useRef, useState } from "react";
import { Trans } from "react-i18next";
import {
    VariableSizeList as List,
    ListChildComponentProps,
    areEqual,
} from "react-window";
import {
    handleSelectCreator,
    handleSelectCreatorMulti,
} from "utils/photoFrame";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";
import PreviewCard from "./pages/gallery/PreviewCard";

export const DATE_CONTAINER_HEIGHT = 48;
export const SPACE_BTW_DATES = 44;

const SPACE_BTW_DATES_TO_IMAGE_CONTAINER_WIDTH_RATIO = 0.244;

const FOOTER_HEIGHT = 90;
const ALBUM_FOOTER_HEIGHT = 75;
const ALBUM_FOOTER_HEIGHT_WITH_REFERRAL = 113;

export enum ITEM_TYPE {
    TIME = "TIME",
    FILE = "FILE",
    HEADER = "HEADER",
    FOOTER = "FOOTER",
    MARKETING_FOOTER = "MARKETING_FOOTER",
    OTHER = "OTHER",
}

export interface TimeStampListItem {
    itemType: ITEM_TYPE;
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

const ListItemContainer = styled(FlexWrapper)<{ span: number }>`
    grid-column: span ${(props) => props.span};
`;

const DateContainer = styled(ListItemContainer)(
    ({ theme }) => `
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    height: ${DATE_CONTAINER_HEIGHT}px;
    color: ${theme.vars.palette.text.muted};
`,
);

const FooterContainer = styled(ListItemContainer)`
    margin-bottom: 0.75rem;
    @media (max-width: 540px) {
        font-size: 12px;
        margin-bottom: 0.5rem;
    }
    text-align: center;
    justify-content: center;
    align-items: flex-end;
    margin-top: calc(2rem + 20px);
`;

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

export interface FileListAnnotatedFile {
    file: EnteFile;
    /**
     * The date string using with the associated {@link file} should be shown in
     * the timeline.
     *
     * This for used for grouping files: all files which have the same
     * {@link timelineDateString} are grouped together into a section titled
     * with that {@link timelineDateString}.
     */
    timelineDateString: string;
}

type FileListProps = Pick<
    PhotoFrameProps,
    | "mode"
    | "modePlus"
    | "selectable"
    | "selected"
    | "setSelected"
    | "favoriteFileIDs"
> & {
    height: number;
    width: number;
    annotatedFiles: FileListAnnotatedFile[];
    showAppDownloadBanner: boolean;
    activeCollectionID: number;
    activePersonID?: string;
    /**
     * Called when the user activates the thumbnail at the given {@link index}.
     *
     * This corresponding file would be at the corresponding index of
     * {@link annotatedFiles}.
     */
    onItemClick: (index: number) => void;
};

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

export const FileList: React.FC<FileListProps> = ({
    height,
    width,
    mode,
    modePlus,
    annotatedFiles,
    showAppDownloadBanner,
    selectable,
    selected,
    setSelected,
    activeCollectionID,
    activePersonID,
    favoriteFileIDs,
    onItemClick,
}) => {
    const galleryContext = useContext(GalleryContext);
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

            if (galleryContext.photoListHeader) {
                timeStampList.push(
                    getPhotoListHeader(galleryContext.photoListHeader),
                );
            } else if (publicCollectionGalleryContext.photoListHeader) {
                timeStampList.push(
                    getPhotoListHeader(
                        publicCollectionGalleryContext.photoListHeader,
                    ),
                );
            }
            if (galleryContext.isClipSearchResult) {
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
            if (publicCollectionGalleryContext.credentials) {
                if (publicCollectionGalleryContext.photoListFooter) {
                    timeStampList.push(
                        getPhotoListFooter(
                            publicCollectionGalleryContext.photoListFooter,
                        ),
                    );
                }
                timeStampList.push(getAlbumsFooter());
            } else if (showAppDownloadBanner) {
                timeStampList.push(getAppDownloadFooter());
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
        galleryContext.photoListHeader,
        publicCollectionGalleryContext.photoListHeader,
        galleryContext.isClipSearchResult,
    ]);

    useEffect(() => {
        setTimeStampList((timeStampList) => {
            timeStampList = timeStampList ?? [];
            const hasHeader =
                timeStampList.length > 0 &&
                timeStampList[0].itemType === ITEM_TYPE.HEADER;

            if (hasHeader) {
                return timeStampList;
            }
            if (galleryContext.photoListHeader) {
                return [
                    getPhotoListHeader(galleryContext.photoListHeader),
                    ...timeStampList,
                ];
            } else if (publicCollectionGalleryContext.photoListHeader) {
                return [
                    getPhotoListHeader(
                        publicCollectionGalleryContext.photoListHeader,
                    ),
                    ...timeStampList,
                ];
            } else {
                return timeStampList;
            }
        });
    }, [
        galleryContext.photoListHeader,
        publicCollectionGalleryContext.photoListHeader,
    ]);

    useEffect(() => {
        setTimeStampList((timeStampList) => {
            timeStampList = timeStampList ?? [];
            const hasFooter =
                timeStampList.length > 0 &&
                timeStampList[timeStampList.length - 1].itemType ===
                    ITEM_TYPE.MARKETING_FOOTER;
            if (hasFooter) {
                return timeStampList;
            }
            if (publicCollectionGalleryContext.credentials) {
                if (publicCollectionGalleryContext.photoListFooter) {
                    return [
                        ...timeStampList,
                        getPhotoListFooter(
                            publicCollectionGalleryContext.photoListFooter,
                        ),
                        getAlbumsFooter(),
                    ];
                }
            } else if (showAppDownloadBanner) {
                return [...timeStampList, getAppDownloadFooter()];
            } else {
                return timeStampList;
            }
        });
    }, [
        publicCollectionGalleryContext.credentials,
        showAppDownloadBanner,
        publicCollectionGalleryContext.photoListFooter,
    ]);

    useEffect(() => {
        refreshList();
    }, [timeStampList]);

    const groupByTime = (timeStampList: TimeStampListItem[]) => {
        let listItemIndex = 0;
        let currentDate;
        annotatedFiles.forEach((item, index) => {
            if (
                !currentDate ||
                !isSameDay(
                    new Date(item.file.metadata.creationTime / 1000),
                    new Date(currentDate),
                )
            ) {
                currentDate = item.file.metadata.creationTime / 1000;

                timeStampList.push({
                    itemType: ITEM_TYPE.TIME,
                    date: item.timelineDateString,
                    id: currentDate.toString(),
                });
                timeStampList.push({
                    itemType: ITEM_TYPE.FILE,
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
                    itemType: ITEM_TYPE.FILE,
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
                    itemType: ITEM_TYPE.FILE,
                    items: [item],
                    itemStartIndex: index,
                });
            }
        });
    };

    const getPhotoListHeader = (photoListHeader) => {
        return {
            ...photoListHeader,
            item: (
                <ListItemContainer span={columns}>
                    {photoListHeader.item}
                </ListItemContainer>
            ),
        };
    };

    const getPhotoListFooter = (photoListFooter) => {
        return {
            ...photoListFooter,
            item: (
                <ListItemContainer span={columns}>
                    {photoListFooter.item}
                </ListItemContainer>
            ),
        };
    };

    const getEmptyListItem = () => {
        return {
            itemType: ITEM_TYPE.OTHER,
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
        const photoFrameHeight = (() => {
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
            itemType: ITEM_TYPE.OTHER,
            item: <></>,
            height: Math.max(height - photoFrameHeight - footerHeight, 0),
        };
    };

    const getAppDownloadFooter = () => {
        return {
            itemType: ITEM_TYPE.MARKETING_FOOTER,
            height: FOOTER_HEIGHT,
            item: (
                <FooterContainer span={columns}>
                    <Typography variant="small" sx={{ color: "text.faint" }}>
                        <Trans
                            i18nKey={"install_mobile_app"}
                            components={{
                                a: (
                                    <Link
                                        href="https://play.google.com/store/apps/details?id=io.ente.photos"
                                        target="_blank"
                                        rel="noopener"
                                    />
                                ),
                                b: (
                                    <Link
                                        href="https://apps.apple.com/in/app/ente-photos/id1542026904"
                                        target="_blank"
                                        rel="noopener"
                                    />
                                ),
                            }}
                        />
                    </Typography>
                </FooterContainer>
            ),
        };
    };

    const getAlbumsFooter = () => {
        return {
            itemType: ITEM_TYPE.MARKETING_FOOTER,
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
        };
    };

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
            if (currItem.itemType === ITEM_TYPE.TIME) {
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
            if (currItem.itemType === ITEM_TYPE.TIME) {
                if (currItem.dates.length > 1) {
                    currItem.groups = currItem.dates.map((item) => item.span);
                    nextItem.groups = currItem.groups;
                }
            }
        }
        return newList;
    };

    const getItemSize = (timeStampList) => (index) => {
        switch (timeStampList[index].itemType) {
            case ITEM_TYPE.TIME:
                return DATE_CONTAINER_HEIGHT;
            case ITEM_TYPE.FILE:
                return listItemHeight;
            default:
                return timeStampList[index].height;
        }
    };

    const generateKey = (index) => {
        switch (timeStampList[index].itemType) {
            case ITEM_TYPE.FILE:
                return `${timeStampList[index].items[0].file.id}-${
                    timeStampList[index].items.slice(-1)[0].file.id
                }`;
            default:
                return `${timeStampList[index].id}-${index}`;
        }
    };

    useEffect(() => {
        // Nothing to do here if nothing is selected.
        if (!galleryContext.selectedFile) return;

        const notSelectedFiles = (annotatedFiles ?? []).filter(
            (item) => !galleryContext.selectedFile[item.file.id],
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
    }, [galleryContext.selectedFile]);

    const handleSelectMulti = handleSelectCreatorMulti(
        galleryContext.setSelectedFiles,
        mode,
        galleryContext?.user?.id,
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

    const handleSelect = handleSelectCreator(
        setSelected,
        mode,
        galleryContext.user?.id,
        activeCollectionID,
        activePersonID,
        setRangeStart,
    );

    const onHoverOver = (index: number) => () => {
        setCurrentHover(index);
    };

    const handleRangeSelect = (index: number) => () => {
        if (typeof rangeStart !== "undefined" && rangeStart !== index) {
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
            if (e.key === "Shift") {
                setIsShiftKeyPressed(true);
            }
        };

        const handleKeyUp = (e: KeyboardEvent) => {
            if (e.key === "Shift") {
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
        <PreviewCard
            key={`tile-${file.id}-selected-${selected[file.id] ?? false}`}
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
                            activeCollectionID)) && selected[file.id]
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
        // Enhancement: This logic doesn't work on the shared album screen, the
        // galleryContext.selectedFile is always null there.
        const haveSelection = (galleryContext.selectedFile?.count ?? 0) > 0;
        switch (listItem.itemType) {
            case ITEM_TYPE.TIME:
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
            case ITEM_TYPE.FILE: {
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
