import { Box, DialogProps, Stack } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import Titlebar from 'components/Titlebar';
import { useEffect, useState } from 'react';
import { t } from 'i18next';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import MapSettings from './MapSettings';
import { getData, LS_KEYS } from 'utils/storage/localStorage';

export default function AdvancedMapSettings({ open, onClose, onRootClose }) {
    const [mapSettingsView, setMapSettingsView] = useState(false);
    const [mapEnabledToggle, setMapEnabledToggle] = useState(false);

    const openMapSettings = () => setMapSettingsView(true);
    const closeMapSettings = () => setMapSettingsView(false);

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
    useEffect(() => {
        const mapEnabledValue = getData(LS_KEYS.MAPENABLED);
        setMapEnabledToggle(mapEnabledValue.mapEnabled);
    }, [mapSettingsView]);

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
                                    onClick={openMapSettings}
                                    variant="toggle"
                                    checked={mapEnabledToggle}
                                    label={t('MAP_SETTINGS')}
                                />
                            </MenuItemGroup>
                        </Box>
                    </Stack>
                </Box>
            </Stack>
            <MapSettings
                open={mapSettingsView}
                onClose={closeMapSettings}
                onRootClose={handleRootClose}
            />
        </EnteDrawer>
    );
}
