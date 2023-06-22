import { Stack, Box } from '@mui/material';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import Titlebar from 'components/Titlebar';
import { t } from 'i18next';

export default function ManageMapEnabled({ onClose, disableMap, onRootClose }) {
    return (
        <Stack spacing={'4px'} py={'12px'}>
            <Titlebar
                onClose={onClose}
                title={t('Map Settings')}
                onRootClose={onRootClose}
            />
            <Box px={'16px'}>
                <Stack py={'20px'} spacing={'24px'}>
                    <MenuItemGroup>
                        <EnteMenuItem
                            onClick={disableMap}
                            label={t('Disable Map')}
                        />
                    </MenuItemGroup>
                </Stack>
            </Box>
        </Stack>
    );
}
