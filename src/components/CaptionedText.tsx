import { Typography } from '@mui/material';
import { VerticallyCenteredFlex } from './Container';

interface Iprops {
    mainText: string;
    subText?: string;
    icon?: React.ReactNode;
}

export const CaptionedText = (props: Iprops) => {
    return (
        <VerticallyCenteredFlex gap={'4px'}>
            <Typography> {props.mainText}</Typography>
            <Typography color="text.muted" variant="small">
                {'•'}
            </Typography>
            {props.subText ? (
                <Typography variant="small" color="text.muted">
                    {props.subText}
                </Typography>
            ) : (
                <Typography variant="small" color="text.muted">
                    {props.icon}
                </Typography>
            )}
        </VerticallyCenteredFlex>
    );
};
