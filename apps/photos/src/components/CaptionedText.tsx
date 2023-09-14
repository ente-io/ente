import { ButtonProps, Typography } from '@mui/material';
import { VerticallyCenteredFlex } from './Container';

interface Iprops {
    mainText: string;
    subText?: string;
    subIcon?: React.ReactNode;
    color?: ButtonProps['color'];
}

const getSubTextColor = (color: ButtonProps['color']) => {
    switch (color) {
        case 'critical':
            return 'critical.main';
        default:
            return 'text.faint';
    }
};

export const CaptionedText = (props: Iprops) => {
    return (
        <VerticallyCenteredFlex gap={'4px'}>
            <Typography> {props.mainText}</Typography>
            <Typography variant="small" color={getSubTextColor(props.color)}>
                {'•'}
            </Typography>
            {props.subText ? (
                <Typography
                    variant="small"
                    color={getSubTextColor(props.color)}>
                    {props.subText}
                </Typography>
            ) : (
                <Typography
                    variant="small"
                    color={getSubTextColor(props.color)}>
                    {props.subIcon}
                </Typography>
            )}
        </VerticallyCenteredFlex>
    );
};
