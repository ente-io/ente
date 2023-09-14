import { ButtonProps, Typography } from '@mui/material';
import { VerticallyCenteredFlex } from './Container';

interface Iprops {
    mainText: string;
    subText?: string;
    subIcon?: React.ReactNode;
    color?: ButtonProps['color'];
}

export const CaptionedText = (props: Iprops) => {
    return (
        <VerticallyCenteredFlex gap={'4px'}>
            <Typography> {props.mainText}</Typography>
            <Typography
                variant="small"
                sx={{
                    color: (theme) =>
                        theme.palette[props.color].main ?? 'text.faint',
                }}>
                {'•'}
            </Typography>
            {props.subText ? (
                <Typography
                    variant="small"
                    sx={{
                        color: (theme) =>
                            theme.palette[props.color].main ?? 'text.faint',
                    }}>
                    {props.subText}
                </Typography>
            ) : (
                <Typography
                    variant="small"
                    sx={{
                        color: (theme) =>
                            theme.palette[props.color].main ?? 'text.faint',
                    }}>
                    {props.subIcon}
                </Typography>
            )}
        </VerticallyCenteredFlex>
    );
};
