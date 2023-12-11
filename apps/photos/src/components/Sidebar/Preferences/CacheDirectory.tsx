import ElectronAPIs from '@ente/shared/electron';
import { addLogLine } from '@ente/shared/logging';
import { logError } from '@ente/shared/sentry';
import Box from '@mui/material/Box';
import { DirectoryPath } from 'components/Directory';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { t } from 'i18next';
import isElectron from 'is-electron';
import { useEffect, useState } from 'react';
import DownloadManager from 'services/download';

export default function CacheDirectory() {
    const [cacheDirectory, setCacheDirectory] = useState(undefined);

    useEffect(() => {
        const main = async () => {
            if (isElectron()) {
                const customCacheDirectory =
                    await ElectronAPIs.getCacheDirectory();
                setCacheDirectory(customCacheDirectory);
            }
        };
        main();
    }, []);

    const handleCacheDirectoryChange = async () => {
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
            setCacheDirectory(newFolder);
            await DownloadManager.reloadCaches();
        } catch (e) {
            logError(e, 'handleCacheDirectoryChange failed');
        }
    };

    return (
        <Box>
            <MenuSectionTitle title={t('CACHE_DIRECTORY')} />
            <MenuItemGroup>
                <EnteMenuItem
                    variant="path"
                    onClick={handleCacheDirectoryChange}
                    labelComponent={
                        <DirectoryPath width={265} path={cacheDirectory} />
                    }
                />
            </MenuItemGroup>
        </Box>
    );
}
