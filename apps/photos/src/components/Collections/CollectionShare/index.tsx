import { Collection, CollectionSummary } from 'types/collection';
import { EnteDrawer } from 'components/EnteDrawer';
import PublicShare from './publicShare';
import { t } from 'i18next';
import { DialogProps, Stack } from '@mui/material';
import Titlebar from 'components/Titlebar';
import EmailShare from './emailShare';
import { CollectionSummaryType } from 'constants/collection';
import SharingDetails from './SharingDetails';

interface Props {
    open: boolean;
    onClose: () => void;
    collection: Collection;
    collectionSummary: CollectionSummary;
}

function CollectionShare({ collectionSummary, ...props }: Props) {
    const handleRootClose = () => {
        props.onClose();
    };
    const handleDrawerClose: DialogProps['onClose'] = (_, reason) => {
        if (reason === 'backdropClick') {
            handleRootClose();
        } else {
            props.onClose();
        }
    };
    if (!props.collection) {
        return <></>;
    }
    const { type } = collectionSummary;

    return (
        <EnteDrawer
            anchor="right"
            open={props.open}
            onClose={handleDrawerClose}
            slotProps={{
                backdrop: {
                    sx: { '&&&': { backgroundColor: 'transparent' } },
                },
            }}>
            <Stack spacing={'4px'} py={'12px'}>
                <Titlebar
                    onClose={props.onClose}
                    title={t('SHARE_COLLECTION')}
                    onRootClose={handleRootClose}
                    caption={props.collection.name}
                />
                <Stack py={'20px'} px={'8px'}>
                    {type === CollectionSummaryType.incomingShareCollaborator ||
                    type === CollectionSummaryType.incomingShareViewer ? (
                        <SharingDetails
                            collection={props.collection}
                            type={type}
                        />
                    ) : (
                        <>
                            <EmailShare
                                collection={props.collection}
                                onRootClose={handleRootClose}
                            />
                            <PublicShare
                                collection={props.collection}
                                onRootClose={handleRootClose}
                            />
                        </>
                    )}
                </Stack>
            </Stack>
        </EnteDrawer>
    );
}
export default CollectionShare;
