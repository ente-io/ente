import { EnteDrawer } from '@ente/shared/components/EnteDrawer';
import { PasskeysContext } from '.';
import { Stack } from '@mui/material';
import Titlebar from '@ente/shared/components/Titlebar';
import { MenuItemGroup } from '@ente/shared/components/Menu/MenuItemGroup';
import { EnteMenuItem } from '@ente/shared/components/Menu/EnteMenuItem';
import { useContext } from 'react';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import MenuItemDivider from '@ente/shared/components/Menu/MenuItemDivider';

interface IProps {
    open: boolean;
}

const ManagePasskeyDrawer = (props: IProps) => {
    const { setShowPasskeyDrawer } = useContext(PasskeysContext);
    return (
        <EnteDrawer
            anchor="right"
            open={props.open}
            onClose={() => {
                setShowPasskeyDrawer(false);
            }}>
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
                <MenuItemGroup>
                    <EnteMenuItem
                        onClick={() => {}}
                        startIcon={<EditIcon />}
                        label={'Rename Passkey'}
                    />
                    <MenuItemDivider />
                    <EnteMenuItem
                        onClick={() => {}}
                        startIcon={<DeleteIcon />}
                        label={'Delete Passkey'}
                    />
                </MenuItemGroup>
            </Stack>
        </EnteDrawer>
    );
};

export default ManagePasskeyDrawer;
