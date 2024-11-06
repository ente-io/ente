import {
    FlexWrapper,
    SpaceBetweenFlex,
} from "@ente/shared/components/Container";
import { Box, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import type React from "react";
import { useMemo } from "react";
import { UserDetails } from "types/user";
import { isPartOfFamily } from "utils/user/family";
import { LegendIndicator, Progressbar } from "../../styledComponents";
import StorageSection from "../storageSection";

interface FamilySubscriptionCardContentProps {
    userDetails: UserDetails;
}

export const FamilySubscriptionCardContent: React.FC<
    FamilySubscriptionCardContentProps
> = ({ userDetails }) => {
    const totalUsage = useMemo(() => {
        if (isPartOfFamily(userDetails.familyData)) {
            return userDetails.familyData.members.reduce(
                (sum, currentMember) => sum + currentMember.usage,
                0,
            );
        } else {
            return userDetails.usage;
        }
    }, [userDetails]);
    const totalStorage =
        userDetails.familyData.storage + (userDetails.storageBonus ?? 0);

    return (
        <>
            <StorageSection storage={totalStorage} usage={totalUsage} />
            <FamilyUsageSection
                userUsage={userDetails.usage}
                fileCount={userDetails.fileCount}
                totalUsage={totalUsage}
                totalStorage={totalStorage}
            />
        </>
    );
};

interface FamilyUsageSectionProps {
    userUsage: number;
    totalUsage: number;
    fileCount: number;
    totalStorage: number;
}

const FamilyUsageSection: React.FC<FamilyUsageSectionProps> = ({
    userUsage,
    totalUsage,
    fileCount,
    totalStorage,
}) => {
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
};

interface FamilyUsageProgressBarProps {
    userUsage: number;
    totalUsage: number;
    totalStorage: number;
}

const FamilyUsageProgressBar: React.FC<FamilyUsageProgressBarProps> = ({
    userUsage,
    totalUsage,
    totalStorage,
}) => {
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
};

interface LegendProps {
    label: string;
    color: string;
}

const Legend: React.FC<LegendProps> = ({ label, color }) => {
    return (
        <FlexWrapper>
            <LegendIndicator sx={{ color }} />
            <Typography variant="mini" fontWeight={"bold"}>
                {label}
            </Typography>
        </FlexWrapper>
    );
};
