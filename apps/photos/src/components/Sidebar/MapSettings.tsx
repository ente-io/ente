import { Box, DialogProps } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import { AppContext } from 'pages/_app';
import { useContext, useState, useEffect } from 'react';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';

// import EnableMapDialog from './EnableMapDialog';
import ManageMapEnabled from './MangeMapEnabled';
import EnableMap from './EnableMap';

const MapSettings = ({ open, onClose, onRootClose }) => {
    const { somethingWentWrong } = useContext(AppContext);

    const [mapEnabled, setMapEnabled] = useState(false);

    useEffect(() => {
        const storedMapEnabled = getData(LS_KEYS.MAPENABLED);
        const initialMapEnabled =
            storedMapEnabled !== null ? storedMapEnabled : false;
        setMapEnabled(initialMapEnabled.mapEnabled);
    }, []);

    useEffect(() => {
        setData(LS_KEYS.MAPENABLED, { mapEnabled });
    }, [mapEnabled]);

    const updateMapEnabled = (enabled) => {
        try {
            setMapEnabled(enabled);
        } catch (e) {
            logError(e, 'Error while updating mapEnabled');
        }
    };

    console.log('MAp enabled from MapSetting', mapEnabled);

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
                    <ManageMapEnabled
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

export default MapSettings;
