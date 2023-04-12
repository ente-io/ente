import { Stack, Box } from '@mui/material';
import SidebarButton, { SidebarButtonProps } from 'components/Sidebar/Button';
import Titlebar from 'components/Titlebar';
import { t } from 'i18next';

const ManageOptions = (props: SidebarButtonProps) => {
    return (
        <SidebarButton
            variant="contained"
            color="secondary"
            {...props}></SidebarButton>
    );
};

export default function ManageMLSearch({
    onClose,
    disableMlSearch,
    handleDisableFaceSearch,
    onRootClose,
}) {
    return (
        <Stack spacing={'4px'} py={'12px'}>
            <Titlebar
                onClose={onClose}
                title={t('ML_SEARCH')}
                onRootClose={onRootClose}
            />
            <Box px={'16px'}>
                <Stack py={'20px'} spacing={'24px'}>
                    <ManageOptions onClick={disableMlSearch}>
                        {t('DISABLE_BETA')}
                    </ManageOptions>
                    <ManageOptions onClick={handleDisableFaceSearch}>
                        {t('DISABLE_FACE_SEARCH')}
                    </ManageOptions>
                </Stack>
            </Box>
        </Stack>
    );
}
