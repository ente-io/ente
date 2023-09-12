import {
    CircularProgressProps,
    Box,
    CircularProgress,
    Typography,
} from '@mui/material';
import { Overlay } from 'components/Container';

function CircularProgressWithLabel(
    props: CircularProgressProps & { value: number }
) {
    return (
        <Box
            sx={{
                position: 'absolute',
                top: '50%',
                left: '50%',
                transform: 'translate(-50%, -50%)',
                zIndex: 10,
            }}>
            <CircularProgress variant="determinate" {...props} color="accent" />
            <Overlay
                sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    height: '40px',
                }}>
                <Typography
                    variant="mini"
                    component="div"
                    color="text.secondary">{`${Math.round(
                    props.value
                )}%`}</Typography>
            </Overlay>
        </Box>
    );
}

export default CircularProgressWithLabel;
