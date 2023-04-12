import React, { useContext } from 'react';
import { t } from 'i18next';

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
            title: t('DISABLE_TWO_FACTOR'),

            content: t('DISABLE_TWO_FACTOR_MESSAGE'),
            close: { text: t('CANCEL') },
            proceed: {
                variant: 'critical',
                text: t('DISABLE'),
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
                title: t('TWO_FACTOR_DISABLE_FAILED'),
                close: {},
            });
        }
    };

    const warnTwoFactorReconfigure = async () => {
        setDialogMessage({
            title: t('UPDATE_TWO_FACTOR'),

            content: t('UPDATE_TWO_FACTOR_MESSAGE'),
            close: { text: t('CANCEL') },
            proceed: {
                variant: 'accent',
                text: t('UPDATE'),
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
                    {t('UPDATE_TWO_FACTOR_LABEL')}
                </Grid>
                <Grid item sm={3} xs={12}>
                    <Button
                        color={'accent'}
                        onClick={warnTwoFactorReconfigure}
                        size="large">
                        {t('RECONFIGURE')}
                    </Button>
                </Grid>
            </Grid>
            <Grid
                rowSpacing={1}
                container
                alignItems="center"
                justifyContent="center">
                <Grid item sm={9} xs={12}>
                    {t('DISABLE_TWO_FACTOR_LABEL')}{' '}
                </Grid>

                <Grid item sm={3} xs={12}>
                    <Button
                        color="critical"
                        onClick={warnTwoFactorDisable}
                        size="large">
                        {t('DISABLE')}
                    </Button>
                </Grid>
            </Grid>
        </>
    );
}
