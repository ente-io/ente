import ChevronRight from '@mui/icons-material/ChevronRight';
import { Box, DialogProps, Stack } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import Titlebar from 'components/Titlebar';
import isElectron from 'is-electron';
import { useState } from 'react';
import { t } from 'i18next';

import AdvancedSettings from '../AdvancedSettings';
import { LanguageSelector } from './LanguageSelector';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';

export default function Preferences({ open, onClose, onRootClose }) {
    const [advancedSettingsView, setAdvancedSettingsView] = useState(false);

    const openAdvancedSettings = () => setAdvancedSettingsView(true);
    const closeAdvancedSettings = () => setAdvancedSettingsView(false);

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
                    title={t('PREFERENCES')}
                    onRootClose={handleRootClose}
                />
                <Box px={'8px'}>
                    <Stack py="20px" spacing="24px">
                        <LanguageSelector />
                        {isElectron() && (
                            <EnteMenuItem
                                onClick={openAdvancedSettings}
                                endIcon={<ChevronRight />}
                                label={t('ADVANCED')}
                            />
                        )}
                    </Stack>
                </Box>
            </Stack>
            <AdvancedSettings
                open={advancedSettingsView}
                onClose={closeAdvancedSettings}
                onRootClose={onRootClose}
            />
        </EnteDrawer>
    );
}
