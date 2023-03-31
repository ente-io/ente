import { Box, Stack, Typography } from '@mui/material';

interface Iprops {
    title: string;
    icon?: JSX.Element;
}

export default function MenuSectionTitle({ title, icon }: Iprops) {
    return (
        <Stack px="8px" py={'6px'} direction="row" spacing={'8px'}>
            {icon && (
                <Box
                    sx={{
                        '& > svg': {
                            fontSize: '17px',
                            color: 'text.muted',
                        },
                    }}>
                    {icon}
                </Box>
            )}
            <Typography variant="small" color="text.muted">
                {title}
            </Typography>
        </Stack>
    );
}
