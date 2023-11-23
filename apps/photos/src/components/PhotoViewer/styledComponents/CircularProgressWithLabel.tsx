import {
    CircularProgressProps,
    CircularProgress,
    Typography,
} from '@mui/material';
import { Overlay } from '@ente/shared/components/Container';

function CircularProgressWithLabel(
    props: CircularProgressProps & { value: number }
) {
    return (
        <>
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
        </>
    );
}

export default CircularProgressWithLabel;
