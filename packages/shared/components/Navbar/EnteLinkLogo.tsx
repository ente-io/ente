import { Box } from '@mui/material';
import Ente from '../../components/icons/ente';
import Link from 'next/link';
import { ENTE_WEBSITE_LINK } from '@ente/shared/constants/urls';

export function EnteLinkLogo() {
    return (
        <Link href={ENTE_WEBSITE_LINK}>
            <Box
                sx={(theme) => ({
                    ':hover': {
                        cursor: 'pointer',
                        svg: {
                            fill: theme.colors.text.faint,
                        },
                    },
                })}>
                <Ente />
            </Box>
        </Link>
    );
}
