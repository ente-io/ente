import { sortPeople, type PeopleSortBy } from "@/utils/people-sort";
import {
    Box,
    Stack,
    Typography,
    styled,
    useMediaQuery,
    useTheme,
} from "@mui/material";
import { ItemCard } from "ente-new/photos/components/Tiles";
import { UnstyledButton } from "ente-new/photos/components/UnstyledButton";
import { thumbnailGridPadding } from "ente-new/photos/components/utils/thumbnail-grid-layout";
import type { Person } from "ente-new/photos/services/ml/people";
import { t } from "i18next";
import { useMemo } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { FixedSizeList, type ListChildComponentProps } from "react-window";
import { PeopleEmptyState } from ".";

export const PeopleOverview = ({
    people,
    peopleSortBy,
    onSelectPerson,
}: {
    people: Person[];
    peopleSortBy: PeopleSortBy;
    onSelectPerson: (id: string) => void;
}) => {
    const mobile = useMediaQuery(useTheme().breakpoints.down("md"));
    const sortedPeople = useMemo(
        () => sortPeople(people, peopleSortBy),
        [people, peopleSortBy],
    );
    return (
        <Stack
            sx={{
                flex: 1,
                minHeight: 0,
                overflow: "hidden",
                px: `${thumbnailGridPadding}px`,
                gap: "24px",
            }}
        >
            <Stack
                direction="row"
                sx={{
                    alignItems: "center",
                    justifyContent: "space-between",
                    minHeight: 54,
                    flexShrink: 0,
                    gap: 2,
                }}
            >
                <Stack sx={{ gap: "2px" }}>
                    <Typography
                        component="h1"
                        sx={{
                            fontFamily: '"Outfit Variable", Outfit, sans-serif',
                            fontSize: 24,
                            fontWeight: 600,
                            lineHeight: "32px",
                        }}
                    >
                        {t("people")}
                    </Typography>
                    <Typography
                        sx={{
                            color: "text.muted",
                            fontSize: 14,
                            fontWeight: 500,
                            lineHeight: "18px",
                        }}
                    >
                        {t("people_count", { count: people.length })}
                    </Typography>
                </Stack>
            </Stack>
            {people.length ? (
                <Box
                    sx={{
                        flex: 1,
                        minHeight: 0,
                        "--people-tile-size": { xs: "96px", md: "140px" },
                        "--people-portrait-size": { xs: "80px", md: "120px" },
                        "--people-column-gap": { xs: "12px", md: "22px" },
                    }}
                >
                    <AutoSizer>
                        {({ width, height }) => {
                            const tileWidth = mobile ? 96 : 140;
                            const gap = mobile ? 12 : 22;
                            const columns = Math.max(
                                1,
                                Math.floor(
                                    (width - 16 + gap) / (tileWidth + gap),
                                ),
                            );
                            return (
                                <FixedSizeList
                                    width={width}
                                    height={height}
                                    itemCount={Math.ceil(
                                        sortedPeople.length / columns,
                                    )}
                                    itemSize={mobile ? 150 : 190}
                                    overscanCount={1}
                                    itemData={{
                                        people: sortedPeople,
                                        columns,
                                        onSelectPerson,
                                    }}
                                >
                                    {PeopleRow}
                                </FixedSizeList>
                            );
                        }}
                    </AutoSizer>
                </Box>
            ) : (
                <PeopleEmptyState />
            )}
        </Stack>
    );
};

const PeopleRow = ({
    data,
    index,
    style,
}: ListChildComponentProps<{
    people: Person[];
    columns: number;
    onSelectPerson: (id: string) => void;
}>) => (
    <div
        style={{
            ...style,
            display: "grid",
            gridTemplateColumns: `repeat(${data.columns}, minmax(0, 1fr))`,
            columnGap: "var(--people-column-gap)",
            justifyItems: "center",
            alignItems: "start",
        }}
    >
        {data.people
            .slice(index * data.columns, (index + 1) * data.columns)
            .map((person) => (
                <PersonButton
                    key={person.id}
                    onClick={() => data.onSelectPerson(person.id)}
                >
                    <ItemCard
                        TileComponent={Portrait}
                        coverFile={person.displayFaceFile}
                        coverFaceID={person.displayFaceID}
                    />
                    <Typography
                        component="span"
                        sx={{
                            fontSize: 14,
                            fontWeight: 500,
                            lineHeight: "20px",
                            width: "100%",
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                            whiteSpace: "nowrap",
                        }}
                    >
                        {person.name || t("unnamed_person")}
                    </Typography>
                    <Typography
                        component="span"
                        sx={{
                            mt: "-6px",
                            fontSize: 12,
                            fontWeight: 500,
                            lineHeight: "16px",
                            color: "text.muted",
                        }}
                    >
                        {t("people_photo_count", {
                            count: person.fileIDs.length,
                        })}
                    </Typography>
                </PersonButton>
            ))}
    </div>
);

const PersonButton = styled(UnstyledButton)({
    width: "var(--people-tile-size)",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: 8,
    color: "inherit",
    borderRadius: 12,
    "&:hover": { opacity: 0.86 },
});

const Portrait = styled("div")({
    width: "var(--people-portrait-size)",
    height: "var(--people-portrait-size)",
    flexShrink: 0,
    borderRadius: "50%",
    overflow: "hidden",
    position: "relative",
    "& > img": { width: "100%", height: "100%", objectFit: "cover" },
});
