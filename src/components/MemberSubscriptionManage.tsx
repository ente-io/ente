import { Box, Button, Dialog, DialogContent, Typography } from '@mui/material';
import VerticallyCentered, { FlexWrapper } from 'components/Container';
import { AppContext } from 'pages/_app';
import React, { useContext, useEffect } from 'react';
import billingService from 'services/billingService';
import { getFamilyPlanAdmin } from 'utils/billing';
import { preloadImage } from 'utils/common';
import constants from 'utils/strings/constants';
import DialogTitleWithCloseButton from './DialogBox/TitleWithCloseButton';

export function MemberSubscriptionManage({ open, userDetails, onClose }) {
    const { setDialogMessage, isMobile } = useContext(AppContext);

    useEffect(() => {
        preloadImage('/images/family-plan');
    }, []);

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
            title: `${constants.LEAVE_FAMILY_PLAN}`,
            content: constants.LEAVE_FAMILY_CONFIRM,
            proceed: {
                text: constants.LEAVE,
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
        <Dialog
            fullWidth
            open={open}
            onClose={onClose}
            maxWidth="xs"
            fullScreen={isMobile}>
            <DialogTitleWithCloseButton onClose={onClose}>
                <Typography variant="h3" fontWeight={'bold'}>
                    {constants.SUBSCRIPTION}
                </Typography>
                <Typography color={'text.secondary'}>
                    {constants.FAMILY_PLAN}
                </Typography>
            </DialogTitleWithCloseButton>
            <DialogContent>
                <VerticallyCentered>
                    <Box mb={4}>
                        <Typography color="text.secondary">
                            {constants.FAMILY_SUBSCRIPTION_INFO}
                        </Typography>
                        <Typography>
                            {getFamilyPlanAdmin(userDetails.familyData)?.email}
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
                            color="danger"
                            onClick={confirmLeaveFamily}>
                            {constants.LEAVE_FAMILY_PLAN}
                        </Button>
                    </FlexWrapper>
                </VerticallyCentered>
            </DialogContent>
        </Dialog>
    );
}
