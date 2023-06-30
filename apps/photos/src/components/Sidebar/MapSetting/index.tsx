import { Box, DialogProps, Stack } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import Titlebar from 'components/Titlebar';
import { useContext, useEffect, useState } from 'react';
import { t } from 'i18next';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import ModifyMapEnabled from './ModifyMapEnabled';
import { getMapEnabledStatus } from 'services/userService';
import { AppContext } from 'pages/_app';

export default function MapSettings({ open, onClose, onRootClose }) {
    const { mapEnabled, updateMapEnabled } = useContext(AppContext);
    const [modifyMapEnabledView, setModifyMapEnabledView] = useState(false);

    const openModifyMapEnabled = () => setModifyMapEnabledView(true);
    const closeModifyMapEnabled = () => setModifyMapEnabledView(false);

    useEffect(() => {
        if (!open) {
            return;
        }
        const main = async () => {
            const remoteMapValue = await getMapEnabledStatus();
            updateMapEnabled(remoteMapValue);
        };
        main();
    }, [open]);

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
        <EnteDrawer
            transitionDuration={0}
            open={open}
            onClose={handleDrawerClose}
            BackdropProps={{
                sx: { '&&&': { backgroundColor: 'transparent' } },
            }}>
            <Stack spacing={'4px'} py={'12px'}>
                <Titlebar
                    onClose={onClose}
                    title={t('MAP')}
                    onRootClose={handleRootClose}
                />

                <Box px={'8px'}>
                    <Stack py="20px" spacing="24px">
                        <Box>
                            <MenuItemGroup>
                                <EnteMenuItem
                                    onClick={openModifyMapEnabled}
                                    variant="toggle"
                                    checked={mapEnabled}
                                    label={t('MAP_SETTINGS')}
                                />
                            </MenuItemGroup>
                        </Box>
                    </Stack>
                </Box>
            </Stack>
            <ModifyMapEnabled
                open={modifyMapEnabledView}
                mapEnabled={mapEnabled}
                onClose={closeModifyMapEnabled}
                onRootClose={handleRootClose}
            />
        </EnteDrawer>
    );
}
