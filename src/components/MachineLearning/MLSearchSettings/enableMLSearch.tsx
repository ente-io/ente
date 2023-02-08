import { Stack, Box, Button } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import Titlebar from 'components/Titlebar';
import { ML_BLOG_LINK } from 'constants/urls';
import { openLink } from 'utils/common';
import constants from 'utils/strings/constants';

export default function EnableMLSearch({
    open,
    onClose,
    enableMlSearch,
    onRootClose,
}) {
    return (
        <EnteDrawer
            hideBackdrop
            open={open}
            onClose={onClose}
            transitionDuration={0}>
            <Stack spacing={'4px'} py={'12px'}>
                <Titlebar
                    onClose={onClose}
                    title={constants.ML_SEARCH}
                    onRootClose={onRootClose}
                />
                <Stack py={'20px'} px={'8px'} spacing={'32px'}>
                    <Box px={'8px'}>{constants.ML_SEARCH_DESCRIPTION()}</Box>
                    <Stack px={'8px'} spacing={'8px'}>
                        <Button
                            color={'accent'}
                            size="large"
                            onClick={enableMlSearch}>
                            {constants.ENABLE}
                        </Button>
                        <Button
                            color={'secondary'}
                            size="large"
                            onClick={() => openLink(ML_BLOG_LINK, true)}>
                            {constants.ML_MORE_DETAILS}
                        </Button>
                    </Stack>
                </Stack>
            </Stack>
        </EnteDrawer>
    );
}
