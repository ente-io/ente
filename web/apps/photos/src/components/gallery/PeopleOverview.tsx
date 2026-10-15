import { sortPeople, type PeopleSortBy } from "@/utils/people-sort";
import { Box, Stack, Typography, styled } from "@mui/material";
import { ItemCard } from "ente-new/photos/components/Tiles";
import { UnstyledButton } from "ente-new/photos/components/UnstyledButton";
import type { Person } from "ente-new/photos/services/ml/people";
import { t } from "i18next";
import { useMemo } from "react";
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
    const sortedPeople = useMemo(
        () => sortPeople(people, peopleSortBy),
        [people, peopleSortBy],
    );
    return (
        <Stack
            sx={{
                flex: 1,
                minHeight: 0,
                overflow: "auto",
                p: { xs: "16px 14px", md: "36px" },
                gap: "24px",
            }}
        >
            <Stack
                direction="row"
                sx={{
                    alignItems: "center",
                    justifyContent: "space-between",
                    minHeight: 54,
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
                        display: "grid",
                        "--people-tile-size": { xs: "96px", md: "140px" },
                        "--people-portrait-size": { xs: "80px", md: "120px" },
                        gridTemplateColumns:
                            "repeat(auto-fill, minmax(var(--people-tile-size), 1fr))",
                        justifyItems: "center",
                        gap: { xs: "24px 12px", md: "24px 22px" },
                    }}
                >
                    {sortedPeople.map((person) => (
                        <PersonButton
                            key={person.id}
                            onClick={() => onSelectPerson(person.id)}
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
                                    overflowWrap: "anywhere",
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
                </Box>
            ) : (
                <PeopleEmptyState />
            )}
        </Stack>
    );
};

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
