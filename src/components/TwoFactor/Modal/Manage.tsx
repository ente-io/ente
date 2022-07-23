import React, { useContext } from 'react';
import constants from 'utils/strings/constants';
import { AppContext } from 'pages/_app';
import { PAGES } from 'constants/pages';
import router from 'next/router';
import { disableTwoFactor } from 'services/userService';
import { setData, LS_KEYS, getData } from 'utils/storage/localStorage';
import { Button, Grid } from '@mui/material';

interface Iprops {
    closeDialog: () => void;
}

export default function TwoFactorModalManageSection(props: Iprops) {
    const { closeDialog } = props;
    const { setDialogMessage } = useContext(AppContext);

    const warnTwoFactorDisable = async () => {
        setDialogMessage({
            title: constants.DISABLE_TWO_FACTOR,

            content: constants.DISABLE_TWO_FACTOR_MESSAGE,
            close: { text: constants.CANCEL },
            proceed: {
                variant: 'danger',
                text: constants.DISABLE,
                action: twoFactorDisable,
            },
        });
    };

    const twoFactorDisable = async () => {
        try {
            await disableTwoFactor();
            setData(LS_KEYS.USER, {
                ...getData(LS_KEYS.USER),
                isTwoFactorEnabled: false,
            });
            closeDialog();
        } catch (e) {
            setDialogMessage({
                title: constants.TWO_FACTOR_DISABLE_FAILED,
                close: {},
            });
        }
    };

    const warnTwoFactorReconfigure = async () => {
        setDialogMessage({
            title: constants.UPDATE_TWO_FACTOR,

            content: constants.UPDATE_TWO_FACTOR_MESSAGE,
            close: { text: constants.CANCEL },
            proceed: {
                variant: 'accent',
                text: constants.UPDATE,
                action: reconfigureTwoFactor,
            },
        });
    };

    const reconfigureTwoFactor = async () => {
        closeDialog();
        router.push(PAGES.TWO_FACTOR_SETUP);
    };

    return (
        <>
            <Grid
                mb={1.5}
                rowSpacing={1}
                container
                alignItems="center"
                justifyContent="center">
                <Grid item sm={9} xs={12}>
                    {constants.UPDATE_TWO_FACTOR_LABEL}
                </Grid>
                <Grid item sm={3} xs={12}>
                    <Button
                        color={'accent'}
                        onClick={warnTwoFactorReconfigure}
                        size="large">
                        {constants.RECONFIGURE}
                    </Button>
                </Grid>
            </Grid>
            <Grid
                rowSpacing={1}
                container
                alignItems="center"
                justifyContent="center">
                <Grid item sm={9} xs={12}>
                    {constants.DISABLE_TWO_FACTOR_LABEL}{' '}
                </Grid>

                <Grid item sm={3} xs={12}>
                    <Button
                        color={'danger'}
                        onClick={warnTwoFactorDisable}
                        size="large">
                        {constants.DISABLE}
                    </Button>
                </Grid>
            </Grid>
        </>
    );
}
