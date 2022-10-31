import CloseIcon from '@mui/icons-material/Close';
import {
    Button,
    ButtonProps,
    IconButton,
    Paper,
    Snackbar,
    Stack,
    Typography,
} from '@mui/material';
import React from 'react';
import { NotificationAttributes } from 'types/Notification';

import InfoIcon from '@mui/icons-material/Info';

interface Iprops {
    open: boolean;
    onClose: () => void;
    attributes: NotificationAttributes;
}

export default function Notification({ open, onClose, attributes }: Iprops) {
    if (!attributes) {
        return <></>;
    }

    const handleClose: ButtonProps['onClick'] = (event) => {
        onClose();
        event.stopPropagation();
    };

    const handleClick = () => {
        attributes.action?.callback();
        onClose();
    };
    return (
        <Snackbar
            open={open}
            anchorOrigin={{
                horizontal: 'right',
                vertical: 'bottom',
            }}
            sx={{ backgroundColor: '#000', width: '320px' }}>
            <Paper
                component={Button}
                color={attributes.variant}
                onClick={handleClick}
                sx={{
                    textAlign: 'left',
                    flex: '1',
                    padding: (theme) => theme.spacing(1.5, 2),
                }}>
                <Stack
                    flex={'1'}
                    spacing={2}
                    direction="row"
                    alignItems={'center'}>
                    {attributes?.icon ?? <InfoIcon />}

                    <Typography
                        variant="body1"
                        mb={0.5}
                        flex={1}
                        textAlign="left">
                        {attributes.message}{' '}
                    </Typography>
                    {attributes?.action && (
                        <Typography
                            mb={0.5}
                            variant="button"
                            fontWeight={'bold'}>
                            {attributes?.action.text}
                        </Typography>
                    )}

                    <IconButton onClick={handleClose}>
                        <CloseIcon />
                    </IconButton>
                </Stack>
            </Paper>
        </Snackbar>
    );
}
