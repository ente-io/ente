import { EnteDrawer } from '@ente/shared/components/EnteDrawer';
import { PasskeysContext } from '.';
import { Stack } from '@mui/material';
import Titlebar from '@ente/shared/components/Titlebar';
import { MenuItemGroup } from '@ente/shared/components/Menu/MenuItemGroup';
import { EnteMenuItem } from '@ente/shared/components/Menu/EnteMenuItem';
import { useContext, useState } from 'react';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import MenuItemDivider from '@ente/shared/components/Menu/MenuItemDivider';
import DeletePasskeyModal from './DeletePasskeyModal';
import RenamePasskeyModal from './RenamePasskeyModal';
import InfoItem from '@ente/shared/components/Info/InfoItem';
import CalendarTodayIcon from '@mui/icons-material/CalendarToday';
import { formatDateTimeFull } from '@ente/shared/time/format';
import { t } from 'i18next';

interface IProps {
    open: boolean;
}

const ManagePasskeyDrawer = (props: IProps) => {
    const { setShowPasskeyDrawer, refreshPasskeys, selectedPasskey } =
        useContext(PasskeysContext);

    const [showDeletePasskeyModal, setShowDeletePasskeyModal] = useState(false);
    const [showRenamePasskeyModal, setShowRenamePasskeyModal] = useState(false);

    return (
        <>
            <EnteDrawer
                anchor="right"
                open={props.open}
                onClose={() => {
                    setShowPasskeyDrawer(false);
                }}>
                {selectedPasskey && (
                    <>
                        <Stack spacing={'4px'} py={'12px'}>
                            <Titlebar
                                onClose={() => {
                                    setShowPasskeyDrawer(false);
                                }}
                                title="Manage Passkey"
                                onRootClose={() => {
                                    setShowPasskeyDrawer(false);
                                }}
                            />
                            <InfoItem
                                icon={<CalendarTodayIcon />}
                                title={t('CREATED_AT')}
                                caption={
                                    `${formatDateTimeFull(
                                        selectedPasskey.createdAt / 1000
                                    )}` || ''
                                }
                                loading={!selectedPasskey}
                                hideEditOption
                            />
                            <MenuItemGroup>
                                <EnteMenuItem
                                    onClick={() => {
                                        setShowRenamePasskeyModal(true);
                                    }}
                                    startIcon={<EditIcon />}
                                    label={'Rename Passkey'}
                                />
                                <MenuItemDivider />
                                <EnteMenuItem
                                    onClick={() => {
                                        setShowDeletePasskeyModal(true);
                                    }}
                                    startIcon={<DeleteIcon />}
                                    label={'Delete Passkey'}
                                    color="critical"
                                />
                            </MenuItemGroup>
                        </Stack>
                    </>
                )}
            </EnteDrawer>
            <DeletePasskeyModal
                open={showDeletePasskeyModal}
                onClose={() => {
                    setShowDeletePasskeyModal(false);
                    refreshPasskeys();
                }}
            />
            <RenamePasskeyModal
                open={showRenamePasskeyModal}
                onClose={() => {
                    setShowRenamePasskeyModal(false);
                    refreshPasskeys();
                }}
            />
        </>
    );
};

export default ManagePasskeyDrawer;
