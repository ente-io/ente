import { Button, Stack, Typography } from '@mui/material';
import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import billingService from 'services/billingService';
import { getFamilyPlanAdmin } from 'utils/billing';
import constants from 'utils/strings/constants';
export function MemberSubscriptionStatus({ userDetails }) {
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
    return (
        <Stack spacing={1}>
            <Typography variant="body2" color="text.secondary ">
                {constants.FAMILY_PLAN_MANAGE_ADMIN_ONLY(
                    getFamilyPlanAdmin(userDetails.familyData)?.email
                )}
            </Typography>
            <Button onClick={confirmLeaveFamily}>
                {constants.LEAVE_FAMILY}
            </Button>
        </Stack>
    );
}
