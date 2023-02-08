import { Box } from '@mui/material';
import { AppContext } from 'pages/_app';
import { useContext, useState } from 'react';
import {
    getFaceSearchStatus,
    updateFaceSearchStatus,
} from 'services/userService';
import { logError } from 'utils/sentry';
import constants from 'utils/strings/constants';
import EnableFaceSearch from './enableFaceSearch';
import EnableMLSearch from './enableMLSearch';
import ManageMLSearch from './manageMLSearch';

const MLSearchSettings = ({ open, onClose, OnRootClose }) => {
    const {
        updateMlSearchEnabled,
        mlSearchEnabled,
        setDialogMessage,
        somethingWentWrong,
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
            const hasEnabledFaceSearch = await getFaceSearchStatus();
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
            await updateFaceSearchStatus(true);
            updateMlSearchEnabled(true);
            closeEnableFaceSearch();
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
            await updateFaceSearchStatus(false);
            await disableMlSearch();
        } catch (e) {
            logError(e, 'Disable face search failed');
            somethingWentWrong();
        }
    };

    const confirmDisableFaceSearch = () => {
        setDialogMessage({
            title: constants.DISABLE_FACE_SEARCH_TITLE,
            content: constants.DISABLE_FACE_SEARCH_DESCRIPTION(),
            close: { text: constants.CANCEL },
            proceed: {
                variant: 'primary',
                text: constants.DISABLE_FACE_SEARCH,
                action: disableFaceSearch,
            },
        });
    };

    return (
        <Box>
            {mlSearchEnabled ? (
                <ManageMLSearch
                    open={open}
                    onClose={onClose}
                    disableMlSearch={disableMlSearch}
                    handleDisableFaceSearch={confirmDisableFaceSearch}
                    onRootClose={OnRootClose}
                />
            ) : (
                <EnableMLSearch
                    open={open}
                    onClose={onClose}
                    enableMlSearch={enableMlSearch}
                    onRootClose={OnRootClose}
                />
            )}

            <EnableFaceSearch
                open={enableFaceSearchView}
                onClose={closeEnableFaceSearch}
                enableFaceSearch={enableFaceSearch}
                onRootClose={OnRootClose}
            />
        </Box>
    );
};

export default MLSearchSettings;
