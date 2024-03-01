import { Divider } from "@mui/material";
interface Iprops {
    hasIcon?: boolean;
}
export default function MenuItemDivider({ hasIcon = false }: Iprops) {
    return (
        <Divider
            sx={{
                "&&&": {
                    my: 0,
                    ml: hasIcon ? "48px" : "16px",
                },
            }}
        />
    );
}
