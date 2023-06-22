import { Box, DialogProps } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import { AppContext } from 'pages/_app';
import { useContext } from 'react';
import { logError } from 'utils/sentry';

// import EnableMapDialog from './EnableMapDialog';
import ManageMapEnabled from './MangeMapEnabled';
import EnableMap from './EnableMap';

const MapSettings = ({ open, onClose, onRootClose }) => {
    const { mapEnabled, updateMapEnabled, somethingWentWrong } =
        useContext(AppContext);

    const disableMap = async () => {
        try {
            await updateMapEnabled(false);
            onClose();
        } catch (e) {
            logError(e, 'Disable Map failed');
            somethingWentWrong();
        }
    };
    const enableMap = async () => {
        try {
            await updateMapEnabled(true);
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
