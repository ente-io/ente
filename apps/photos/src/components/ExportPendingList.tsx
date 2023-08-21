import { EnteFile } from 'types/file';
import { ResultItemContainer } from './Upload/UploadProgress/styledComponents';
import ItemList from 'components/ItemList';
import DialogBoxV2 from './DialogBoxV2';
import { t } from 'i18next';
import { FlexWrapper } from './Container';
import CollectionCard from './Collections/CollectionCard';
import { ResultPreviewTile } from './Collections/styledComponents';
import { Box } from '@mui/material';

interface Iprops {
    isOpen: boolean;
    onClose: () => void;
    collectionNameMap: Map<number, string>;
    pendingExports: EnteFile[];
}

const ExportPendingList = (props: Iprops) => {
    const renderListItem = (file: EnteFile) => {
        return (
            <ResultItemContainer key={file.id} sx={{ marginBottom: '2px' }}>
                <FlexWrapper>
                    <Box sx={{ marginRight: '8px' }}>
                        <CollectionCard
                            key={file.id}
                            coverFile={file}
                            onClick={() => null}
                            collectionTile={ResultPreviewTile}
                        />
                    </Box>
                    {`${props.collectionNameMap.get(file.collectionID)} / ${
                        file.metadata.title
                    }`}
                </FlexWrapper>
            </ResultItemContainer>
        );
    };

    const getItemTitle = (file: EnteFile) => {
        return `${props.collectionNameMap.get(file.collectionID)} - ${
            file.metadata.title
        }`;
    };

    const generateItemKey = (file: EnteFile) => {
        return `${file.collectionID}-${file.id}`;
    };

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
            <ItemList
                maxHeight={240}
                itemSize={50}
                items={props.pendingExports}
                renderListItem={renderListItem}
                getItemTitle={getItemTitle}
                generateItemKey={generateItemKey}
            />
        </DialogBoxV2>
    );
};

export default ExportPendingList;
