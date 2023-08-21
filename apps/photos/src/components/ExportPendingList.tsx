import { EnteFile } from 'types/file';
import { ResultItemContainer } from './Upload/UploadProgress/styledComponents';
import FileList from 'components/FileList';
import { useEffect, useState } from 'react';
import { getCollectionNameMap } from 'utils/collection';
import { getLocalCollections } from 'services/collectionService';
import { getLocalFiles, getLocalHiddenFiles } from 'services/fileService';
import exportService from 'services/export';
import { getUnExportedFiles } from 'utils/export';
import { mergeMetadata, getPersonalFiles } from 'utils/file';
import { LS_KEYS, getData } from 'utils/storage/localStorage';
import DialogBoxV2 from './DialogBoxV2';
import { t } from 'i18next';
import { FlexWrapper } from './Container';
import CollectionCard from './Collections/CollectionCard';
import { ResultPreviewTile } from './Collections/styledComponents';
import { Box } from '@mui/material';

interface Iprops {
    isOpen: boolean;
    onClose: () => void;
}

const ExportPendingList = (props: Iprops) => {
    const [collectionNameMap, setCollectionNameMap] = useState(new Map());
    const [pendingFiles, setPendingFiles] = useState<EnteFile[]>([]);

    useEffect(() => {
        const main = async () => {
            const collections = await getLocalCollections();
            setCollectionNameMap(getCollectionNameMap(collections));

            const exportFolder = exportService.getExportSettings()?.folder;
            if (!exportFolder) {
                return [];
            }
            const exportRecord = await exportService.getExportRecord(
                exportFolder
            );

            const files = mergeMetadata([
                ...(await getLocalFiles()),
                ...(await getLocalHiddenFiles()),
            ]);
            const user = getData(LS_KEYS.USER);
            const personalFiles = getPersonalFiles(files, user);

            const filesToExport = getUnExportedFiles(
                personalFiles,
                exportRecord
            );

            setPendingFiles(filesToExport);
        };
        main();
    }, []);

    return (
        <DialogBoxV2
            open={props.isOpen}
            onClose={props.onClose}
            attributes={{
                title: t('PENDING_ITEMS'),
                close: {
                    action: props.onClose,
                    text: t('CLOSE'),
                },
            }}
            size="xs">
            <FileList
                maxHeight={240}
                itemSize={50}
                fileList={pendingFiles.map((file) => (
                    <ResultItemContainer
                        key={file.id}
                        sx={{ marginBottom: '2px' }}>
                        <FlexWrapper>
                            <Box sx={{ marginRight: '8px' }}>
                                <CollectionCard
                                    key={file.id}
                                    coverFile={file}
                                    onClick={() => null}
                                    collectionTile={ResultPreviewTile}
                                />
                            </Box>
                            {`${collectionNameMap.get(file.collectionID)} - ${
                                file.metadata.title
                            }`}
                        </FlexWrapper>
                    </ResultItemContainer>
                ))}
            />
        </DialogBoxV2>
    );
};

export default ExportPendingList;
