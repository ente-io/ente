import { Divider } from '@mui/material';
interface Iprops {
    hasIcon?: boolean;
}
export default function EnteMenuItemDivider({ hasIcon = false }: Iprops) {
    return hasIcon ? (
        <Divider
            sx={{
                '&&&': {
                    my: 0,
                    ml: 6,
                },
            }}
        />
    ) : (
        <Divider
            sx={{
                '&&&': {
                    my: 0,
                    ml: 2,
                },
            }}
        />
    );
}
