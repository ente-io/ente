import CloseIcon from '@mui/icons-material/Close';
import {
    Box,
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
            }}>
            <Paper
                component={Button}
                color={attributes.variant}
                onClick={handleClick}
                sx={{
                    textAlign: 'left',
                    width: '320px',
                    padding: (theme) => theme.spacing(1.5, 2),
                }}>
                <Stack
                    flex={'1'}
                    spacing={2}
                    direction="row"
                    alignItems={'center'}>
                    <Box>
                        {attributes?.icon ?? <InfoIcon fontSize="large" />}
                    </Box>
                    <Box sx={{ flex: 1 }}>
                        <Typography
                            variant="body2"
                            color="rgba(255, 255, 255, 0.7)"
                            mb={0.5}>
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
                    </Box>
                    <Box>
                        <IconButton
                            onClick={handleClose}
                            sx={{
                                backgroundColor: 'rgba(255, 255, 255, 0.1)',
                            }}>
                            <CloseIcon />
                        </IconButton>
                    </Box>
                </Stack>
            </Paper>
        </Snackbar>
    );
}
