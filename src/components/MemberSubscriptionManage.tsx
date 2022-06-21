import { Button, DialogContent, Typography } from '@mui/material';
import VerticallyCentered from 'components/Container';
import DialogBoxBase from 'components/DialogBox/base';
import DialogTitleWithCloseButton from 'components/DialogBox/titleWithCloseButton';
import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import billingService from 'services/billingService';
import { getFamilyPlanAdmin } from 'utils/billing';
import constants from 'utils/strings/constants';
export function MemberSubscriptionManage({ open, userDetails, onClose }) {
    const { setDialogMessage } = useContext(AppContext);

    async function onLeaveFamilyClick() {
        try {
            await billingService.leaveFamily();
        } catch (e) {
            setDialogMessage({
                title: constants.ERROR,
                close: { variant: 'danger' },
                content: constants.UNKNOWN_ERROR,
            });
        }
    }
    const confirmLeaveFamily = () =>
        setDialogMessage({
            title: `${constants.LEAVE_FAMILY}`,
            content: constants.LEAVE_FAMILY_CONFIRM,
            proceed: {
                text: constants.LEAVE_FAMILY,
                action: onLeaveFamilyClick,
                variant: 'danger',
            },
            close: {
                text: constants.CANCEL,
            },
        });

    if (!userDetails) {
        return <></>;
    }

    return (
        <DialogBoxBase open={open} onClose={onClose} maxWidth="xs">
            <DialogTitleWithCloseButton onClose={onClose}>
                <Typography variant="h3">{constants.SUBSCRIPTION}</Typography>
                <Typography color={'text.secondary'}>
                    {constants.FAMILY_PLAN}
                </Typography>
            </DialogTitleWithCloseButton>
            <DialogContent>
                <VerticallyCentered>
                    <Typography color="text.secondary ">
                        {constants.FAMILY_SUBSCRIPTION_INFO(
                            getFamilyPlanAdmin(userDetails.familyData)?.email
                        )}
                    </Typography>
                    <img
                        height="312px"
                        width="232px"
                        src="/images/family_plan_leave@3x.png"
                    />
                    <Button
                        size="large"
                        variant="outlined"
                        color="danger"
                        onClick={confirmLeaveFamily}>
                        {constants.LEAVE_FAMILY}
                    </Button>
                </VerticallyCentered>
            </DialogContent>
        </DialogBoxBase>
    );
}
