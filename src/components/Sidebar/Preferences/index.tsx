import ChevronRight from '@mui/icons-material/ChevronRight';
import { Box, DialogProps, Stack } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import Titlebar from 'components/Titlebar';
import isElectron from 'is-electron';
import { useState } from 'react';
import constants from 'utils/strings/constants';
import AdvancedSettings from '../AdvancedSettings';
import SidebarButton from '../Button';
import { LanguageSelector } from './LanguageSelector';

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
                    title={constants.PREFERENCES}
                    onRootClose={handleRootClose}
                />
                <Box px={'8px'}>
                    <Stack py="20px" spacing="24px">
                        <Box>
                            <MenuSectionTitle title={constants.LANGUAGE} />
                            <LanguageSelector />
                        </Box>
                        {isElectron() && (
                            <SidebarButton
                                variant="contained"
                                color="secondary"
                                onClick={openAdvancedSettings}
                                endIcon={<ChevronRight />}>
                                {constants.ADVANCED}
                            </SidebarButton>
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
