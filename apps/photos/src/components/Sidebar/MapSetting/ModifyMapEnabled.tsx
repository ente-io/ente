import { Box, DialogProps } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import { AppContext } from 'pages/_app';
import { useContext, useState, useEffect } from 'react';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import EnableMap from '../EnableMap';
import DisableMap from '../DisableMap';
import { updateMapEnabledStatus } from 'services/userService';

const ModifyMapEnabled = ({ open, onClose, onRootClose }) => {
    const { somethingWentWrong } = useContext(AppContext);

    const [mapEnabled, setMapEnabled] = useState(false);

    useEffect(() => {
        const main = async () => {
            const storedMapEnabled = getData(LS_KEYS.MAPENABLED);
            const initialMapEnabled =
                storedMapEnabled !== null ? storedMapEnabled.mapEnabled : false;
            setMapEnabled(initialMapEnabled);
        };
        main();
    }, []);

    const updateMapEnabled = (enabled) => {
        try {
            updateMapEnabledStatus(mapEnabled);
            setMapEnabled(enabled);
            setData(LS_KEYS.MAPENABLED, { mapEnabled });
        } catch (e) {
            logError(e, 'Error while updating mapEnabled');
        }
    };

    const disableMap = async () => {
        try {
            updateMapEnabled(false);
            onClose();
        } catch (e) {
            logError(e, 'Disable Map failed');
            somethingWentWrong();
        }
    };

    const enableMap = async () => {
        try {
            updateMapEnabled(true);
            onClose();
        } catch (e) {
            logError(e, 'Enable Map failed');
            somethingWentWrong();
        }
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
                {mapEnabled ? (
                    <DisableMap
                        onClose={onClose}
                        disableMap={disableMap}
                        onRootClose={handleRootClose}
                    />
                ) : (
                    <EnableMap
                        onClose={onClose}
                        enableMap={enableMap}
                        onRootClose={handleRootClose}
                    />
                )}
            </EnteDrawer>
        </Box>
    );
};

export default ModifyMapEnabled;
