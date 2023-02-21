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
                            color: 'text.secondary',
                        },
                    }}>
                    {icon}
                </Box>
            )}
            <Typography variant="body2" color="text.secondary">
                {title}
            </Typography>
        </Stack>
    );
}
