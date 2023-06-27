import ChevronRight from '@mui/icons-material/ChevronRight';
import ScienceIcon from '@mui/icons-material/Science';
import { Box, DialogProps, Stack } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import MLSearchSettings from 'components/MachineLearning/MLSearchSettings';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import Titlebar from 'components/Titlebar';
import { useState } from 'react';
import { t } from 'i18next';

import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';

export default function AdvancedSettings({ open, onClose, onRootClose }) {
    const [mlSearchSettingsView, setMlSearchSettingsView] = useState(false);

    const openMlSearchSettings = () => setMlSearchSettingsView(true);
    const closeMlSearchSettings = () => setMlSearchSettingsView(false);

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
                    title={t('ADVANCED')}
                    onRootClose={handleRootClose}
                />

                <Box px={'8px'}>
                    <Stack py="20px" spacing="24px">
                        <Box>
                            <MenuSectionTitle
                                title={t('LABS')}
                                icon={<ScienceIcon />}
                            />
                            <MenuItemGroup>
                                <EnteMenuItem
                                    endIcon={<ChevronRight />}
                                    onClick={openMlSearchSettings}
                                    label={t('ML_SEARCH')}
                                />
                            </MenuItemGroup>
                        </Box>
                    </Stack>
                </Box>
            </Stack>
            <MLSearchSettings
                open={mlSearchSettingsView}
                onClose={closeMlSearchSettings}
                onRootClose={handleRootClose}
            />
        </EnteDrawer>
    );
}
