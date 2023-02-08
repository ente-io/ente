import ChevronRight from '@mui/icons-material/ChevronRight';
import ScienceIcon from '@mui/icons-material/Science';
import { Box, Stack } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import MLSearchSettings from 'components/MachineLearning/MLSearchSettings';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import Titlebar from 'components/Titlebar';
import { useState } from 'react';
import constants from 'utils/strings/constants';
import SidebarButton from './Button';

export default function AdvancedSettings({ open, onClose, onRootClose }) {
    const [mlSearchSettingsView, setMlSearchSettingsView] = useState(false);

    const openMlSearchSettings = () => setMlSearchSettingsView(true);
    const closeMlSearchSettings = () => setMlSearchSettingsView(false);
    return (
        <EnteDrawer
            hideBackdrop
            transitionDuration={0}
            open={open}
            onClose={onClose}
            BackdropProps={{
                sx: { '&&&': { backgroundColor: 'transparent' } },
            }}>
            <Stack spacing={'4px'} py={'12px'}>
                <Titlebar
                    onClose={onClose}
                    title={constants.ADVANCED}
                    onRootClose={onRootClose}
                />

                <Box px={'8px'}>
                    <Stack py="20px" spacing="24px">
                        <Box>
                            <MenuSectionTitle
                                title={constants.LABS}
                                icon={<ScienceIcon />}
                            />
                            <SidebarButton
                                variant="contained"
                                color="secondary"
                                endIcon={<ChevronRight />}
                                onClick={openMlSearchSettings}>
                                {constants.ML_SEARCH}
                            </SidebarButton>
                        </Box>
                    </Stack>
                </Box>
            </Stack>
            <MLSearchSettings
                open={mlSearchSettingsView}
                onClose={closeMlSearchSettings}
                OnRootClose={onRootClose}
            />
        </EnteDrawer>
    );
}
