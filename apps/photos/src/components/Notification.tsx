import CloseIcon from '@mui/icons-material/Close';
import {
    Box,
    Button,
    ButtonProps,
    Snackbar,
    Stack,
    SxProps,
    Theme,
    Typography,
} from '@mui/material';
import { NotificationAttributes } from 'types/Notification';

import InfoIcon from '@mui/icons-material/InfoOutlined';
import { IconButtonWithBG } from '@ente/shared/components/Container';

interface Iprops {
    open: boolean;
    onClose: () => void;
    keepOpenOnClick?: boolean;
    attributes: NotificationAttributes;
    horizontal?: 'left' | 'right';
    vertical?: 'top' | 'bottom';
    sx?: SxProps<Theme>;
}

export default function Notification({
    open,
    onClose,
    horizontal,
    vertical,
    sx,
    attributes,
    keepOpenOnClick,
}: Iprops) {
    if (!attributes) {
        return <></>;
    }

    const handleClose: ButtonProps['onClick'] = (event) => {
        onClose();
        event.stopPropagation();
    };

    const handleClick = () => {
        attributes.onClick();
        if (!keepOpenOnClick) {
            onClose();
        }
    };
    return (
        <Snackbar
            open={open}
            anchorOrigin={{
                horizontal: horizontal ?? 'right',
                vertical: vertical ?? 'bottom',
            }}
            sx={{ width: '320px', backgroundColor: '#000', ...sx }}>
            <Button
                color={attributes.variant}
                onClick={handleClick}
                sx={{
                    textAlign: 'left',
                    flex: '1',
                    padding: (theme) => theme.spacing(1.5, 2),
                    borderRadius: '8px',
                }}>
                <Stack
                    flex={'1'}
                    spacing={2}
                    direction="row"
                    alignItems={'center'}>
                    <Box sx={{ svg: { fontSize: '36px' } }}>
                        {attributes.startIcon ?? <InfoIcon />}
                    </Box>

                    <Stack
                        direction={'column'}
                        spacing={0.5}
                        flex={1}
                        textAlign="left">
                        {attributes.subtext && (
                            <Typography variant="small">
                                {attributes.subtext}
                            </Typography>
                        )}
                        {attributes.message && (
                            <Typography fontWeight="bold">
                                {attributes.message}
                            </Typography>
                        )}
                        {attributes.title && (
                            <Typography fontWeight="bold">
                                {attributes.title}
                            </Typography>
                        )}
                        {attributes.caption && (
                            <Typography variant="small">
                                {attributes.caption}
                            </Typography>
                        )}
                    </Stack>

                    {attributes.endIcon ? (
                        <IconButtonWithBG
                            onClick={attributes.onClick}
                            sx={{ fontSize: '36px' }}>
                            {attributes?.endIcon}
                        </IconButtonWithBG>
                    ) : (
                        <IconButtonWithBG onClick={handleClose}>
                            <CloseIcon />
                        </IconButtonWithBG>
                    )}
                </Stack>
            </Button>
        </Snackbar>
    );
}
