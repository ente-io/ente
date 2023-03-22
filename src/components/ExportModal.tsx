import isElectron from 'is-electron';
import React, { useEffect, useState, useContext } from 'react';
import exportService from 'services/exportService';
import { ExportProgress, ExportStats } from 'types/export';
import { getLocalFiles } from 'services/fileService';
import {
    Button,
    Dialog,
    DialogContent,
    Divider,
    Stack,
    styled,
    Tooltip,
} from '@mui/material';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { FlexWrapper, Label, Value } from './Container';
import ExportFinished from './ExportFinished';
import ExportInit from './ExportInit';
import ExportInProgress from './ExportInProgress';
import FolderIcon from '@mui/icons-material/Folder';
import { ExportStage } from 'constants/export';
import DialogTitleWithCloseButton from './DialogBox/TitleWithCloseButton';
import MoreHoriz from '@mui/icons-material/MoreHoriz';
import OverflowMenu from './OverflowMenu/menu';
import { OverflowMenuOption } from './OverflowMenu/option';
import { CustomError } from 'utils/error';
import { AppContext } from 'pages/_app';
import { getExportDirectoryDoesNotExistMessage } from 'utils/ui';
import { t } from 'i18next';
import { getUserPersonalFiles } from 'utils/file';

const ExportFolderPathContainer = styled('span')`
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    width: 100%;

    /* Beginning of string */
    direction: rtl;
    text-align: left;
`;

interface Props {
    show: boolean;
    onHide: () => void;
}
export default function ExportModal(props: Props) {
    const appContext = useContext(AppContext);
    const [exportStage, setExportStage] = useState(ExportStage.INIT);
    const [exportFolder, setExportFolder] = useState('');
    const [totalFileCount, setTotalFileCount] = useState(0);
    const [exportProgress, setExportProgress] = useState<ExportProgress>({
        current: 0,
        total: 0,
    });
    const [exportStats, setExportStats] = useState<ExportStats>({
        failed: 0,
        success: 0,
    });
    const [lastExportTime, setLastExportTime] = useState(0);

    // ====================
    // SIDE EFFECTS
    // ====================
    useEffect(() => {
        if (!isElectron()) {
            return;
        }
        try {
            setExportFolder(getData(LS_KEYS.EXPORT)?.folder);

            exportService.electronAPIs.registerStopExportListener(
                stopExportHandler
            );
        } catch (e) {
            logError(e, 'error in exportModal');
        }
    }, []);

    useEffect(() => {
        if (!exportFolder) {
            return;
        }
        const main = async () => {
            try {
                const exportInfo = await exportService.getExportRecord();
                setExportStage(exportInfo?.stage ?? ExportStage.INIT);
                setLastExportTime(exportInfo?.lastAttemptTimestamp);
                setExportProgress(
                    exportInfo?.progress ?? { current: 0, total: 0 }
                );
                setExportStats({
                    success: exportInfo?.exportedFiles?.length ?? 0,
                    failed: exportInfo?.failedFiles?.length ?? 0,
                });
                if (exportInfo?.stage === ExportStage.INPROGRESS) {
                    await startExport();
                }
            } catch (e) {
                logError(e, 'error handling exportFolder change');
            }
        };
        void main();
    }, [exportFolder]);

    useEffect(() => {
        if (!props.show) {
            return;
        }
        void updateTotalFileCount();
    }, [props.show]);

    const updateTotalFileCount = async () => {
        try {
            const userPersonalFiles = getUserPersonalFiles(
                await getLocalFiles()
            );
            setTotalFileCount(userPersonalFiles?.length ?? 0);
        } catch (e) {
            logError(e, 'updateTotalFileCount failed');
        }
    };

    // =============
    // STATE UPDATERS
    // ==============
    const updateExportFolder = (newFolder: string) => {
        setExportFolder(newFolder);
        setData(LS_KEYS.EXPORT, { folder: newFolder });
    };

    const updateExportStage = async (newStage: ExportStage) => {
        setExportStage(newStage);
        await exportService.updateExportRecord({ stage: newStage });
    };

    const updateExportTime = async (newTime: number) => {
        setLastExportTime(newTime);
        await exportService.updateExportRecord({
            lastAttemptTimestamp: newTime,
        });
    };

    const updateExportProgress = async (newProgress: ExportProgress) => {
        setExportProgress(newProgress);
        await exportService.updateExportRecord({ progress: newProgress });
    };

    // ======================
    // HELPER FUNCTIONS
    // =========================

    const preExportRun = async () => {
        const exportFolder = getData(LS_KEYS.EXPORT)?.folder;
        if (!exportFolder) {
            await selectExportDirectory();
        }
        const exportFolderExists = exportService.exists(exportFolder);
        if (!exportFolderExists) {
            appContext.setDialogMessage(
                getExportDirectoryDoesNotExistMessage()
            );
            return;
        }
        await updateExportStage(ExportStage.INPROGRESS);
    };

    const postExportRun = async () => {
        await updateExportStage(ExportStage.FINISHED);
        await updateExportTime(Date.now());
        await syncExportStatsWithRecord();
    };

    const selectExportDirectory = async () => {
        const newFolder = await exportService.selectExportDirectory();
        if (newFolder) {
            updateExportFolder(newFolder);
        } else {
            throw Error(CustomError.REQUEST_CANCELLED);
        }
    };

    const syncExportStatsWithRecord = async () => {
        const exportRecord = await exportService.getExportRecord();
        const failed = exportRecord?.failedFiles?.length ?? 0;
        const success = exportRecord?.exportedFiles?.length ?? 0;
        setExportStats({ failed, success });
    };

    // =============
    // UI functions
    // =============

    const startExport = async () => {
        try {
            await preExportRun();

            const exportRecord = await exportService.getExportRecord();
            const exportedFileCount = exportRecord?.exportedFiles?.length ?? 0;
            updateExportProgress({
                current: exportedFileCount,
                total: totalFileCount,
            });

            const updateExportStatsWithOffset = (current: number) =>
                updateExportProgress({
                    current: exportedFileCount + current,
                    total: totalFileCount,
                });
            await exportService.exportFiles(updateExportStatsWithOffset);

            await postExportRun();
        } catch (e) {
            if (e.message !== CustomError.REQUEST_CANCELLED) {
                logError(e, 'resumeExport failed');
            }
        }
    };

    const stopExport = async () => {
        try {
            exportService.stopRunningExport();
            await postExportRun();
        } catch (e) {
            if (e.message !== CustomError.REQUEST_CANCELLED) {
                logError(e, 'stopExport failed');
            }
        }
    };

    const startExportHandler = () => {
        void startExport();
    };
    const stopExportHandler = () => {
        void stopExport();
    };

    const ExportDynamicContent = () => {
        switch (exportStage) {
            case ExportStage.INIT:
                return <ExportInit startExport={startExportHandler} />;

            case ExportStage.INPROGRESS:
                return (
                    <ExportInProgress
                        exportStage={exportStage}
                        exportProgress={exportProgress}
                        stopExport={stopExportHandler}
                        closeExportDialog={props.onHide}
                    />
                );
            case ExportStage.FINISHED:
                return (
                    <ExportFinished
                        onHide={props.onHide}
                        lastExportTime={lastExportTime}
                        exportStats={exportStats}
                        startExport={startExportHandler}
                    />
                );

            default:
                return <></>;
        }
    };

    return (
        <Dialog open={props.show} onClose={props.onHide} maxWidth="xs">
            <DialogTitleWithCloseButton onClose={props.onHide}>
                {t('EXPORT_DATA')}
            </DialogTitleWithCloseButton>
            <DialogContent>
                <Stack spacing={2}>
                    <ExportDirectory
                        exportFolder={exportFolder}
                        selectExportDirectory={selectExportDirectory}
                        exportStage={exportStage}
                    />
                    <TotalFileCount totalFileCount={totalFileCount} />
                </Stack>
            </DialogContent>
            <Divider />
            <ExportDynamicContent />
        </Dialog>
    );
}

function ExportDirectory({ exportFolder, selectExportDirectory, exportStage }) {
    return (
        <FlexWrapper>
            <Label width="30%">{t('DESTINATION')}</Label>
            <Value width="70%">
                {!exportFolder ? (
                    <Button color={'accent'} onClick={selectExportDirectory}>
                        {t('SELECT_FOLDER')}
                    </Button>
                ) : (
                    <>
                        <Tooltip title={exportFolder}>
                            <ExportFolderPathContainer>
                                {exportFolder}
                            </ExportFolderPathContainer>
                        </Tooltip>
                        {(exportStage === ExportStage.FINISHED ||
                            exportStage === ExportStage.INIT) && (
                            <ExportDirectoryOption
                                selectExportDirectory={selectExportDirectory}
                            />
                        )}
                    </>
                )}
            </Value>
        </FlexWrapper>
    );
}

function TotalFileCount({ totalFileCount }) {
    return (
        <FlexWrapper>
            <Label width="30%">{t('TOTAL_FILE_COUNT')} </Label>
            <Value width="70%">{totalFileCount}</Value>
        </FlexWrapper>
    );
}

function ExportDirectoryOption({ selectExportDirectory }) {
    const handleClick = () => {
        try {
            selectExportDirectory();
        } catch (e) {
            if (e.message !== CustomError.REQUEST_CANCELLED) {
                logError(e, 'startExport failed');
            }
        }
    };
    return (
        <OverflowMenu
            triggerButtonProps={{
                sx: {
                    ml: 1,
                },
            }}
            ariaControls={'export-option'}
            triggerButtonIcon={<MoreHoriz />}>
            <OverflowMenuOption
                onClick={handleClick}
                startIcon={<FolderIcon />}>
                {t('CHANGE_FOLDER')}
            </OverflowMenuOption>
        </OverflowMenu>
    );
}
