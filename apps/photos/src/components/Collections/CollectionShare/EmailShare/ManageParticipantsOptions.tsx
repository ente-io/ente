import { Stack } from '@mui/material';
import { Collection } from 'types/collection';
import { EnteDrawer } from 'components/EnteDrawer';
import { t } from 'i18next';
import { DialogProps } from '@mui/material';
import Titlebar from 'components/Titlebar';
import { ManageParticipantsList } from './ManageParticipantsList';

interface Iprops {
    collection: Collection;

    open: boolean;
    onClose: () => void;
    onRootClose: () => void;

    peopleCount: number;
}

export default function ManageParticipantsOptions({
    open,
    collection,
    onClose,
    onRootClose,
    peopleCount,
}: Iprops) {
    const handleDrawerClose: DialogProps['onClose'] = (_, reason) => {
        if (reason === 'backdropClick') {
            onRootClose();
        } else {
            onClose();
        }
    };

    return (
        <>
            <EnteDrawer anchor="right" open={open} onClose={handleDrawerClose}>
                <Stack spacing={'4px'} py={'12px'}>
                    <Titlebar
                        onClose={onClose}
                        title={collection.name}
                        onRootClose={onRootClose}
                        caption={`${peopleCount}${t('PARTICIPANTS')} `}
                    />
                    <Stack py={'20px'} px={'8px'} spacing={'8px'}>
                        <ManageParticipantsList
                            collection={collection}
                            onRootClose={onRootClose}
                        />
                    </Stack>
                </Stack>
            </EnteDrawer>
        </>
    );
}
