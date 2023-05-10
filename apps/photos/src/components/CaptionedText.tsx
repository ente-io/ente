import { Typography } from '@mui/material';
import { VerticallyCenteredFlex } from './Container';

interface Iprops {
    mainText: string;
    subText?: string;
    subIcon?: React.ReactNode;
}

export const CaptionedText = (props: Iprops) => {
    return (
        <VerticallyCenteredFlex gap={'4px'}>
            <Typography> {props.mainText}</Typography>
            <Typography color="text.faint" variant="small">
                {'•'}
            </Typography>
            {props.subText ? (
                <Typography variant="small" color="text.faint">
                    {props.subText}
                </Typography>
            ) : (
                <Typography variant="small" color="text.faint">
                    {props.subIcon}
                </Typography>
            )}
        </VerticallyCenteredFlex>
    );
};
