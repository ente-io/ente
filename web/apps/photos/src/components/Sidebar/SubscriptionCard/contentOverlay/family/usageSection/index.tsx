import {
    FlexWrapper,
    SpaceBetweenFlex,
} from "@ente/shared/components/Container";
import { Box, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { LegendIndicator, Progressbar } from "../../../styledComponents";

interface Iprops {
    userUsage: number;
    totalUsage: number;
    fileCount: number;
    totalStorage: number;
}

export function FamilyUsageSection({
    userUsage,
    totalUsage,
    fileCount,
    totalStorage,
}: Iprops) {
    return (
        <Box width="100%">
            <FamilyUsageProgressBar
                totalUsage={totalUsage}
                userUsage={userUsage}
                totalStorage={totalStorage}
            />
            <SpaceBetweenFlex
                sx={{
                    marginTop: 1.5,
                }}
            >
                <Stack direction={"row"} spacing={1.5}>
                    <Legend label={t("YOU")} color="text.base" />
                    <Legend label={t("FAMILY")} color="text.muted" />
                </Stack>
                <Typography variant="mini" fontWeight={"bold"}>
                    {t("photos_count", { count: fileCount ?? 0 })}
                </Typography>
            </SpaceBetweenFlex>
        </Box>
    );
}

interface FamilyUsageProgressBarProps {
    userUsage: number;
    totalUsage: number;
    totalStorage: number;
}

function FamilyUsageProgressBar({
    userUsage,
    totalUsage,
    totalStorage,
}: FamilyUsageProgressBarProps) {
    return (
        <Box position={"relative"} width="100%">
            <Progressbar
                sx={{ backgroundColor: "transparent" }}
                value={Math.min((userUsage * 100) / totalStorage, 100)}
            />
            <Progressbar
                sx={{
                    position: "absolute",
                    top: 0,
                    zIndex: 1,
                    ".MuiLinearProgress-bar ": {
                        backgroundColor: "text.muted",
                    },
                    width: "100%",
                }}
                value={Math.min((totalUsage * 100) / totalStorage, 100)}
            />
        </Box>
    );
}

interface LegendProps {
    label: string;
    color: string;
}

function Legend({ label, color }: LegendProps) {
    return (
        <FlexWrapper>
            <LegendIndicator sx={{ color }} />
            <Typography variant="mini" fontWeight={"bold"}>
                {label}
            </Typography>
        </FlexWrapper>
    );
}
