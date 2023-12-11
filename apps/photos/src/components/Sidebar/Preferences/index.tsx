import ChevronRight from '@mui/icons-material/ChevronRight';
import { Box, Button, DialogProps, Stack, Tooltip } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import Titlebar from 'components/Titlebar';
import isElectron from 'is-electron';
import { useEffect, useState } from 'react';
import { t } from 'i18next';

import AdvancedSettings from '../AdvancedSettings';
import MapSettings from '../MapSetting';
import { LanguageSelector } from './LanguageSelector';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { LS_KEYS } from '@ente/shared/storage/localStorage';
import { useLocalState } from '@ente/shared/hooks/useLocalState';
import ElectronAPIs from '@ente/shared/electron';
import InMemoryStore, { MS_KEYS } from '@ente/shared/storage/InMemoryStore';
import { logError } from '@ente/shared/sentry';
import { ExportDirectoryOption } from 'components/ExportModal';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { addLogLine } from '@ente/shared/logging';

export default function Preferences({ open, onClose, onRootClose }) {
    const [advancedSettingsView, setAdvancedSettingsView] = useState(false);
    const [mapSettingsView, setMapSettingsView] = useState(false);
    const [optOutOfCrashReports, setOptOutOfCrashReports] = useLocalState(
        LS_KEYS.OPT_OUT_OF_CRASH_REPORTS,
        false
    );
    const [customCacheDirectory, setCustomCacheDirectory] = useLocalState(
        LS_KEYS.CUSTOM_CACHE_DIRECTORY,
        undefined
    );

    useEffect(() => {
        const main = async () => {
            if (isElectron()) {
                const customCacheDirectory =
                    await ElectronAPIs.getCustomCacheDirectory();
                setCustomCacheDirectory(customCacheDirectory);
            }
        };
        main();
    }, []);

    const openAdvancedSettings = () => setAdvancedSettingsView(true);
    const closeAdvancedSettings = () => setAdvancedSettingsView(false);

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

    const toggleOptOutOfCrashReports = async () => {
        try {
            if (isElectron()) {
                await ElectronAPIs.updateOptOutOfCrashReports(
                    !optOutOfCrashReports
                );
            }
            setOptOutOfCrashReports(!optOutOfCrashReports);
            InMemoryStore.set(
                MS_KEYS.OPT_OUT_OF_CRASH_REPORTS,
                !optOutOfCrashReports
            );
        } catch (e) {
            logError(e, 'toggleOptOutOfCrashReports failed');
        }
    };

    const handleCustomCacheDirectoryChange = async () => {
        try {
            if (!isElectron()) {
                return;
            }
            const newFolder = await ElectronAPIs.selectDirectory();
            if (!newFolder) {
                return;
            }
            addLogLine(`Export folder changed to ${newFolder}`);
            await ElectronAPIs.setCustomCacheDirectory(newFolder);
            setCustomCacheDirectory(newFolder);
        } catch (e) {
            logError(e, 'changeCustomCacheDirectory failed');
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
                        <EnteMenuItem
                            variant="toggle"
                            checked={!optOutOfCrashReports}
                            onClick={toggleOptOutOfCrashReports}
                            label={t('CRASH_REPORTING')}
                        />

                        <Box>
                            <MenuSectionTitle
                                title={t('CUSTOM_CACHE_DIRECTORY')}
                            />
                            <MenuItemGroup>
                                {customCacheDirectory ? (
                                    <Tooltip title={customCacheDirectory}>
                                        <span>{customCacheDirectory}</span>
                                    </Tooltip>
                                ) : (
                                    <Button
                                        color={'accent'}
                                        onClick={
                                            handleCustomCacheDirectoryChange
                                        }>
                                        {t('SELECT_FOLDER')}
                                    </Button>
                                )}
                                <ExportDirectoryOption
                                    changeExportDirectory={
                                        handleCustomCacheDirectoryChange
                                    }
                                />
                            </MenuItemGroup>
                        </Box>

                        <EnteMenuItem
                            onClick={openMapSettings}
                            endIcon={<ChevronRight />}
                            label={t('MAP')}
                        />
                        <EnteMenuItem
                            onClick={openAdvancedSettings}
                            endIcon={<ChevronRight />}
                            label={t('ADVANCED')}
                        />
                    </Stack>
                </Box>
            </Stack>
            <AdvancedSettings
                open={advancedSettingsView}
                onClose={closeAdvancedSettings}
                onRootClose={onRootClose}
            />
            <MapSettings
                open={mapSettingsView}
                onClose={closeMapSettings}
                onRootClose={onRootClose}
            />
        </EnteDrawer>
    );
}
