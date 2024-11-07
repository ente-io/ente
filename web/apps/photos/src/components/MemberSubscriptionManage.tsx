import { useIsSmallWidth } from "@/base/hooks";
import { familyAdminEmail, leaveFamily } from "@/new/photos/services/plan";
import { useAppContext } from "@/new/photos/types/context";
import {
    FlexWrapper,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import DialogTitleWithCloseButton from "@ente/shared/components/DialogBox/TitleWithCloseButton";
import { Box, Button, Dialog, DialogContent, Typography } from "@mui/material";
import { t } from "i18next";

export function MemberSubscriptionManage({ open, userDetails, onClose }) {
    const { showMiniDialog } = useAppContext();
    const fullScreen = useIsSmallWidth();

    const confirmLeaveFamily = () =>
        showMiniDialog({
            title: t("LEAVE_FAMILY_PLAN}"),
            message: t("LEAVE_FAMILY_CONFIRM"),
            continue: {
                text: t("LEAVE"),
                color: "critical",
                action: leaveFamily,
            },
        });

    if (!userDetails) {
        return <></>;
    }

    return (
        <Dialog {...{ open, onClose, fullScreen }} maxWidth="xs" fullWidth>
            <DialogTitleWithCloseButton onClose={onClose}>
                <Typography variant="h3" fontWeight={"bold"}>
                    {t("SUBSCRIPTION")}
                </Typography>
                <Typography color={"text.muted"}>{t("FAMILY_PLAN")}</Typography>
            </DialogTitleWithCloseButton>
            <DialogContent>
                <VerticallyCentered>
                    <Box mb={4}>
                        <Typography color="text.muted">
                            {t("subscription_info_family")}
                        </Typography>
                        <Typography>
                            {familyAdminEmail(userDetails) ?? ""}
                        </Typography>
                    </Box>

                    <img
                        height={256}
                        src="/images/family-plan/1x.png"
                        srcSet="/images/family-plan/2x.png 2x,
                                /images/family-plan/3x.png 3x"
                    />
                    <FlexWrapper px={2}>
                        <Button
                            size="large"
                            variant="outlined"
                            color="critical"
                            onClick={confirmLeaveFamily}
                        >
                            {t("LEAVE_FAMILY_PLAN")}
                        </Button>
                    </FlexWrapper>
                </VerticallyCentered>
            </DialogContent>
        </Dialog>
    );
}
