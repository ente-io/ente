import { Overlay } from "@/base/components/containers";
import type { ButtonishProps } from "@/base/components/mui";
import type { UserDetails } from "@/new/photos/services/user-details";
import {
    familyUsage,
    isPartOfFamilyWithOtherMembers,
} from "@/new/photos/services/user-details";
import { bytesInGB, formattedStorageByteSize } from "@/new/photos/utils/units";
import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import CircleIcon from "@mui/icons-material/Circle";
import {
    Box,
    LinearProgress,
    Skeleton,
    Stack,
    Typography,
    styled,
    type LinearProgressProps,
} from "@mui/material";
import { t } from "i18next";
import type React from "react";

interface SubscriptionCardProps {
    /**
     * Details for the logged in user.
     *
     * Can be undefined if the fetch has not yet completed.
     */
    userDetails: UserDetails | undefined;
    /**
     * Called when the user clicks on the card.
     */
    onClick: () => void;
}

/**
 * The card in the sidebar that shows a summary of the user's plan and usage.
 */
export const SubscriptionCard: React.FC<SubscriptionCardProps> = ({
    userDetails,
    onClick,
}) =>
    !userDetails ? (
        <Skeleton
            animation="wave"
            variant="rectangular"
            height={152}
            sx={{ borderRadius: "8px" }}
        />
    ) : (
        <Box sx={{ position: "relative" }}>
            <BackgroundOverlay />
            <SubscriptionCardContentOverlay userDetails={userDetails} />
            <ClickOverlay onClick={onClick} />
        </Box>
    );

const BackgroundOverlay: React.FC = () => (
    <img
        style={{ aspectRatio: "2/1" }}
        width="100%"
        src="/images/subscription-card-background/1x.png"
        srcSet="/images/subscription-card-background/2x.png 2x, /images/subscription-card-background/3x.png 3x"
    />
);

const ClickOverlay: React.FC<ButtonishProps> = ({ onClick }) => (
    <Overlay
        sx={{
            display: "flex",
            justifyContent: "flex-end",
            alignItems: "center",
            cursor: "pointer",
        }}
        onClick={onClick}
    >
        <ChevronRightIcon />
    </Overlay>
);

interface SubscriptionCardContentOverlayProps {
    userDetails: UserDetails;
}

export const SubscriptionCardContentOverlay: React.FC<
    SubscriptionCardContentOverlayProps
> = ({ userDetails }) => (
    <Overlay>
        <Stack
            sx={{
                height: "100%",
                justifyContent: "space-between",
                padding: "20px 16px",
            }}
        >
            {isPartOfFamilyWithOtherMembers(userDetails) ? (
                <FamilySubscriptionCardContents userDetails={userDetails} />
            ) : (
                <IndividualSubscriptionCardContents userDetails={userDetails} />
            )}
        </Stack>
    </Overlay>
);

const IndividualSubscriptionCardContents: React.FC<
    SubscriptionCardContentOverlayProps
> = ({ userDetails }) => {
    const totalStorage =
        userDetails.subscription.storage + userDetails.storageBonus;

    return (
        <>
            <StorageSection storage={totalStorage} usage={userDetails.usage} />
            <IndividualUsageSection
                usage={userDetails.usage}
                fileCount={userDetails.fileCount}
                storage={totalStorage}
            />
        </>
    );
};

const MobileSmallBox = styled("div")`
    display: none;
    @media (max-width: 359px) {
        display: block;
    }
`;

const DefaultBox = styled("div")`
    display: none;
    @media (min-width: 360px) {
        display: block;
    }
`;

interface StorageSectionProps {
    usage: number;
    storage: number;
}

const StorageSection: React.FC<StorageSectionProps> = ({ usage, storage }) => (
    <Box sx={{ width: "100%" }}>
        <Typography variant="small" sx={{ color: "text.muted" }}>
            {t("storage")}
        </Typography>
        <DefaultBox>
            <Typography variant="h3">
                {`${formattedStorageByteSize(usage, { round: true })} ${t(
                    "of",
                )} ${formattedStorageByteSize(storage)} ${t("used")}`}
            </Typography>
        </DefaultBox>
        <MobileSmallBox>
            <Typography variant="h3">
                {`${bytesInGB(usage)} /  ${bytesInGB(storage)} ${t("storage_unit.gb")} ${t("used")}`}
            </Typography>
        </MobileSmallBox>
    </Box>
);

interface IndividualUsageSectionProps {
    usage: number;
    fileCount: number;
    storage: number;
}

const IndividualUsageSection: React.FC<IndividualUsageSectionProps> = ({
    usage,
    storage,
    fileCount,
}) => {
    // [Note: Fallback translation for languages with multiple plurals]
    //
    // Languages like Polish and Arabian have multiple plural forms, and
    // currently i18n falls back to the base language translation instead of the
    // "_other" form if all the plural forms are not listed out.
    //
    // As a workaround, name the _other form as the unprefixed name. That is,
    // instead of calling the most general plural form as foo_count_other, call
    // it foo_count (To keep our heads straight, we adopt the convention that
    // all such pluralizable strings use the _count suffix, but that's not a
    // requirement from the library).
    return (
        <Box sx={{ width: "100%" }}>
            <UsageBar used={usage} total={storage} />
            <SpaceBetweenFlex sx={{ marginTop: 1.5 }}>
                <Typography variant="mini">{`${formattedStorageByteSize(
                    storage - usage,
                )} ${t("free")}`}</Typography>
                <Typography variant="mini" sx={{ fontWeight: "medium" }}>
                    {t("photos_count", { count: fileCount ?? 0 })}
                </Typography>
            </SpaceBetweenFlex>
        </Box>
    );
};

const FamilySubscriptionCardContents: React.FC<
    SubscriptionCardContentOverlayProps
> = ({ userDetails }) => {
    const totalUsage = familyUsage(userDetails);
    const totalStorage =
        (userDetails.familyData?.storage ?? 0) + userDetails.storageBonus;

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
        <Box sx={{ width: "100%" }}>
            <FamilyUsageBar
                totalUsage={totalUsage}
                userUsage={userUsage}
                totalStorage={totalStorage}
            />
            <SpaceBetweenFlex sx={{ marginTop: 1.5 }}>
                <Stack direction={"row"} spacing={1.5}>
                    <Legend label={t("you")} color="text.base" />
                    <Legend label={t("family")} color="text.muted" />
                </Stack>
                <Typography variant="mini" sx={{ fontWeight: "medium" }}>
                    {t("photos_count", { count: fileCount ?? 0 })}
                </Typography>
            </SpaceBetweenFlex>
        </Box>
    );
};

interface FamilyUsageBarProps {
    userUsage: number;
    totalUsage: number;
    totalStorage: number;
}

const FamilyUsageBar: React.FC<FamilyUsageBarProps> = ({
    userUsage,
    totalUsage,
    totalStorage,
}) => (
    <Box sx={{ position: "relative", width: "100%" }}>
        <UsageBar
            used={userUsage}
            total={totalStorage}
            sx={{ backgroundColor: "transparent" }}
        />
        <UsageBar
            used={totalUsage}
            total={totalStorage}
            sx={{
                position: "absolute",
                top: 0,
                zIndex: 1,
                ".MuiLinearProgress-bar ": {
                    backgroundColor: "text.muted",
                },
                width: "100%",
            }}
        />
    </Box>
);

type UsageBarProps = Pick<LinearProgressProps, "sx"> & {
    used: number;
    total: number;
};

const UsageBar: React.FC<UsageBarProps> = ({ used, total, sx }) => (
    <UsageBar_
        variant="determinate"
        sx={sx}
        value={Math.min(used / total, 1) * 100}
    />
);

const UsageBar_ = styled(LinearProgress)(({ theme }) => ({
    ".MuiLinearProgress-bar": {
        borderRadius: "2px",
    },
    borderRadius: "2px",
    backgroundColor: theme.vars.palette.fixed.storageCardUsageFill,
}));

interface LegendProps {
    label: string;
    color: string;
}

const Legend: React.FC<LegendProps> = ({ label, color }) => (
    <Stack direction="row" sx={{ alignItems: "center" }}>
        <LegendDot sx={{ color }} />
        <Typography variant="mini" sx={{ fontWeight: "medium" }}>
            {label}
        </Typography>
    </Stack>
);

const LegendDot = styled(CircleIcon)`
    font-size: 8.71px;
    margin: 0;
    margin-inline-end: 4px;
    color: inherit;
`;
