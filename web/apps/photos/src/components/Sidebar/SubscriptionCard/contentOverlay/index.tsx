import { formattedStorageByteSize } from "@/new/photos/utils/units";
import { Overlay, SpaceBetweenFlex } from "@ente/shared/components/Container";
import { Box, Typography } from "@mui/material";
import { t } from "i18next";
import { UserDetails } from "types/user";
import { hasNonAdminFamilyMembers } from "utils/user/family";
import { Progressbar } from "../styledComponents";
import { FamilySubscriptionCardContent } from "./family";
import StorageSection from "./storageSection";

interface SubscriptionCardContentOverlayPprops {
    userDetails: UserDetails;
}

export const SubscriptionCardContentOverlay: React.FC<
    SubscriptionCardContentOverlayPprops
> = ({ userDetails }) => {
    return (
        <Overlay>
            <SpaceBetweenFlex
                height={"100%"}
                flexDirection={"column"}
                padding={"20px 16px"}
            >
                {hasNonAdminFamilyMembers(userDetails.familyData) ? (
                    <FamilySubscriptionCardContent userDetails={userDetails} />
                ) : (
                    <IndividualSubscriptionCardContent
                        userDetails={userDetails}
                    />
                )}
            </SpaceBetweenFlex>
        </Overlay>
    );
};

interface IndividualSubscriptionCardContentProps {
    userDetails: UserDetails;
}

const IndividualSubscriptionCardContent: React.FC<
    IndividualSubscriptionCardContentProps
> = ({ userDetails }) => {
    const totalStorage =
        userDetails.subscription.storage + (userDetails.storageBonus ?? 0);
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
        <Box width="100%">
            <Progressbar value={Math.min((usage * 100) / storage, 100)} />
            <SpaceBetweenFlex
                sx={{
                    marginTop: 1.5,
                }}
            >
                <Typography variant="mini">{`${formattedStorageByteSize(
                    storage - usage,
                )} ${t("FREE")}`}</Typography>
                <Typography variant="mini" fontWeight={"bold"}>
                    {t("photos_count", { count: fileCount ?? 0 })}
                </Typography>
            </SpaceBetweenFlex>
        </Box>
    );
};
