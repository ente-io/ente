import ChevronRight from '@mui/icons-material/ChevronRight';
// import ScienceIcon from '@mui/icons-material/Science';
import { Box, DialogProps, Stack } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
// import MLSearchSettings from 'components/MachineLearning/MLSearchSettings';
// import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import Titlebar from 'components/Titlebar';
import { useState } from 'react';
import { t } from 'i18next';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import MapSettings from './MapSettings';

export default function AdvancedMApSettings({ open, onClose, onRootClose }) {
    const [mapSettingsView, setMapSettingsView] = useState(false);

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
                    title={t('Map')}
                    onRootClose={handleRootClose}
                />

                <Box px={'8px'}>
                    <Stack py="20px" spacing="24px">
                        <Box>
                            {/* <MenuSectionTitle
                                title={t('LABS')}
                                icon={<ScienceIcon />}
                            /> */}
                            <MenuItemGroup>
                                <EnteMenuItem
                                    endIcon={<ChevronRight />}
                                    onClick={openMapSettings}
                                    label={t('Map Settings')}
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
