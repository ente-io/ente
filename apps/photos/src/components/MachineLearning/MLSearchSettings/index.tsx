import { Box, DialogProps, Typography } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import { AppContext } from 'pages/_app';
import { useContext, useState } from 'react';
import { Trans } from 'react-i18next';
import { t } from 'i18next';
import {
    getFaceSearchEnabledStatus,
    updateFaceSearchEnabledStatus,
} from 'services/userService';
import { logError } from '@ente/shared/sentry';
import EnableFaceSearch from './enableFaceSearch';
import EnableMLSearch from './enableMLSearch';
import ManageMLSearch from './manageMLSearch';

const MLSearchSettings = ({ open, onClose, onRootClose }) => {
    const {
        updateMlSearchEnabled,
        mlSearchEnabled,
        setDialogMessage,
        somethingWentWrong,
        startLoading,
        finishLoading,
    } = useContext(AppContext);

    const [enableFaceSearchView, setEnableFaceSearchView] = useState(false);

    const openEnableFaceSearch = () => {
        setEnableFaceSearchView(true);
    };
    const closeEnableFaceSearch = () => {
        setEnableFaceSearchView(false);
    };

    const enableMlSearch = async () => {
        try {
            const hasEnabledFaceSearch = await getFaceSearchEnabledStatus();
            if (!hasEnabledFaceSearch) {
                openEnableFaceSearch();
            } else {
                updateMlSearchEnabled(true);
            }
        } catch (e) {
            logError(e, 'Enable ML search failed');
            somethingWentWrong();
        }
    };

    const enableFaceSearch = async () => {
        try {
            startLoading();
            await updateFaceSearchEnabledStatus(true);
            updateMlSearchEnabled(true);
            closeEnableFaceSearch();
            finishLoading();
        } catch (e) {
            logError(e, 'Enable face search failed');
            somethingWentWrong();
        }
    };

    const disableMlSearch = async () => {
        try {
            await updateMlSearchEnabled(false);
            onClose();
        } catch (e) {
            logError(e, 'Disable ML search failed');
            somethingWentWrong();
        }
    };

    const disableFaceSearch = async () => {
        try {
            startLoading();
            await updateFaceSearchEnabledStatus(false);
            await disableMlSearch();
            finishLoading();
        } catch (e) {
            logError(e, 'Disable face search failed');
            somethingWentWrong();
        }
    };

    const confirmDisableFaceSearch = () => {
        setDialogMessage({
            title: t('DISABLE_FACE_SEARCH_TITLE'),
            content: (
                <Typography>
                    <Trans i18nKey={'DISABLE_FACE_SEARCH_DESCRIPTION'} />
                </Typography>
            ),
            close: { text: t('CANCEL') },
            proceed: {
                variant: 'primary',
                text: t('DISABLE_FACE_SEARCH'),
                action: disableFaceSearch,
            },
        });
    };

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleDrawerClose: DialogProps['onClose'] = (_, reason) => {
        if (reason === 'backdropClick') {
            handleRootClose();
        } else {
            onClose();
        }
    };

    return (
        <Box>
            <EnteDrawer
                anchor="left"
                transitionDuration={0}
                open={open}
                onClose={handleDrawerClose}
                BackdropProps={{
                    sx: { '&&&': { backgroundColor: 'transparent' } },
                }}>
                {mlSearchEnabled ? (
                    <ManageMLSearch
                        onClose={onClose}
                        disableMlSearch={disableMlSearch}
                        handleDisableFaceSearch={confirmDisableFaceSearch}
                        onRootClose={handleRootClose}
                    />
                ) : (
                    <EnableMLSearch
                        onClose={onClose}
                        enableMlSearch={enableMlSearch}
                        onRootClose={handleRootClose}
                    />
                )}
            </EnteDrawer>

            <EnableFaceSearch
                open={enableFaceSearchView}
                onClose={closeEnableFaceSearch}
                enableFaceSearch={enableFaceSearch}
                onRootClose={handleRootClose}
            />
        </Box>
    );
};

export default MLSearchSettings;
