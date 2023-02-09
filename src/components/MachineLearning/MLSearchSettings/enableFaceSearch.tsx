import {
    Stack,
    Box,
    Button,
    FormGroup,
    Checkbox,
    FormControlLabel,
} from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import Titlebar from 'components/Titlebar';
import { useEffect, useState } from 'react';
import constants from 'utils/strings/constants';

export default function EnableFaceSearch({
    open,
    onClose,
    enableFaceSearch,
    onRootClose,
}) {
    const [acceptTerms, setAcceptTerms] = useState(false);

    useEffect(() => {
        setAcceptTerms(false);
    }, [open]);

    return (
        <EnteDrawer
            transitionDuration={0}
            open={open}
            onClose={onClose}
            BackdropProps={{
                onClick: onRootClose,
                sx: { '&&&': { backgroundColor: 'transparent' } },
            }}>
            <Stack spacing={'4px'} py={'12px'}>
                <Titlebar
                    onClose={onClose}
                    title={constants.ENABLE_FACE_SEARCH_TITLE}
                    onRootClose={onRootClose}
                />
                <Stack py={'20px'} px={'8px'} spacing={'32px'}>
                    <Box px={'8px'}>
                        {constants.ENABLE_FACE_SEARCH_DESCRIPTION()}
                    </Box>
                    <FormGroup sx={{ width: '100%' }}>
                        <FormControlLabel
                            sx={{
                                color: 'text.secondary',
                                ml: 0,
                                mt: 2,
                            }}
                            control={
                                <Checkbox
                                    size="small"
                                    checked={acceptTerms}
                                    onChange={(e) =>
                                        setAcceptTerms(e.target.checked)
                                    }
                                />
                            }
                            label={constants.FACE_SEARCH_CONFIRMATION}
                        />
                    </FormGroup>
                    <Stack px={'8px'} spacing={'8px'}>
                        <Button
                            color={'accent'}
                            size="large"
                            disabled={!acceptTerms}
                            onClick={enableFaceSearch}>
                            {constants.ENABLE_FACE_SEARCH}
                        </Button>
                        <Button
                            color={'secondary'}
                            size="large"
                            onClick={onClose}>
                            {constants.CANCEL}
                        </Button>
                    </Stack>
                </Stack>
            </Stack>
        </EnteDrawer>
    );
}
