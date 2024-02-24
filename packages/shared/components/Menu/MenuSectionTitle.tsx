import { VerticallyCenteredFlex } from "@ente/shared/components/Container";
import { Typography } from "@mui/material";

interface Iprops {
    title: string;
    icon?: JSX.Element;
}

export default function MenuSectionTitle({ title, icon }: Iprops) {
    return (
        <VerticallyCenteredFlex
            px="8px"
            py={"6px"}
            gap={"8px"}
            sx={{
                "& > svg": {
                    fontSize: "17px",
                    color: (theme) => theme.colors.stroke.muted,
                },
            }}
        >
            {icon && icon}
            <Typography variant="small" color="text.muted">
                {title}
            </Typography>
        </VerticallyCenteredFlex>
    );
}
