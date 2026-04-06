import { Paper, Stack, styled, Typography } from "@mui/material";
import { CenteredFill } from "ente-base/components/containers";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { NavbarBase } from "ente-base/components/Navbar";

export const PublicAccessLayout: React.FC<React.PropsWithChildren> = ({
    children,
}) => (
    <Stack
        sx={[
            { minHeight: "100svh", bgcolor: "secondary.main" },
            (theme) =>
                theme.applyStyles("dark", { bgcolor: "background.default" }),
        ]}
    >
        <NavbarBase
            sx={{
                boxShadow: "none",
                borderBottom: "none",
                bgcolor: "transparent",
            }}
        >
            <EnteLogo />
        </NavbarBase>
        <CenteredFill
            sx={[
                { bgcolor: "secondary.main" },
                (theme) =>
                    theme.applyStyles("dark", {
                        bgcolor: "background.default",
                    }),
            ]}
        >
            <PublicAccessPagePaper>{children}</PublicAccessPagePaper>
        </CenteredFill>
    </Stack>
);

const PublicAccessPagePaper = styled(Paper)(({ theme }) => ({
    marginBlock: theme.spacing(2),
    padding: theme.spacing(5, 3),
    [theme.breakpoints.up("sm")]: { padding: theme.spacing(5) },
    width: "min(420px, 85vw)",
    minHeight: "375px",
    display: "flex",
    flexDirection: "column",
    gap: theme.spacing(4),
    boxShadow: "none",
    borderRadius: "20px",
}));

export const PublicAccessLayoutTitle: React.FC<React.PropsWithChildren> = ({
    children,
}) => (
    <Typography variant="h3" sx={{ flex: 1 }}>
        {children}
    </Typography>
);
