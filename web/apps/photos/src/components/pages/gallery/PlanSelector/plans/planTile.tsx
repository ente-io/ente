import { styled } from "@mui/material";

const PlanTile = styled("div")<{ current: boolean }>(({ theme, current }) => ({
    padding: theme.spacing(3),
    border: `1px solid ${theme.palette.divider}`,

    "&:hover": {
        backgroundColor: " rgba(40, 214, 101, 0.11)",
        cursor: "pointer",
    },
    ...(current && {
        borderColor: theme.colors.accent.A500,
        cursor: "not-allowed",
        "&:hover": { backgroundColor: "transparent" },
    }),
    width: " 260px",
    "@media (min-width: 1152px)": {
        "&:first-of-type": {
            borderTopLeftRadius: "8px",
        },

        "&:last-of-type": {
            borderTopRightRadius: "8px",
        },
    },
    "@media (max-width: 1151px) and (min-width:551px)": {
        "&:first-of-type": {
            borderTopLeftRadius: "8px",
        },

        "&:nth-of-type(2)": {
            borderTopRightRadius: "8px",
        },
    },
    "@media (max-width: 551px)": {
        "&:first-of-type": {
            borderTopLeftRadius: "8px",
            borderTopRightRadius: "8px",
        },
    },
}));

export default PlanTile;
