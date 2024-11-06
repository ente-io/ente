import {
    FlexWrapper,
    SpaceBetweenFlex,
} from "@ente/shared/components/Container";
import { Box, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { LegendIndicator } from "../../../styledComponents";
import { FamilyUsageProgressBar } from "./progressBar";

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
