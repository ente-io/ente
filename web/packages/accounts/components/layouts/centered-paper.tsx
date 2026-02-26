import { Paper, Stack, styled, Typography } from "@mui/material";
import { CenteredFill } from "ente-base/components/containers";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { NavbarBase } from "ente-base/components/Navbar";

/**
 * An ad-hoc component that abstracts the layout common to many of the pages
 * exported by the the accounts package.
 *
 * The layout is roughly:
 * - Set height to 100vh
 * - An app bar at the top
 * - Center a {@link Paper} in the rest of the space.
 * - The children passed to this component go within this {@link Paper}.
 *
 * {@link AccountsPageTitle} and {@link AccountsPageFooter} are meant to be used
 * in tandem with, as children of, {@link AccountsPageContents}.
 */
export const AccountsPageContents: React.FC<React.PropsWithChildren> = ({
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
            <AccountsPagePaper>{children}</AccountsPagePaper>
        </CenteredFill>
    </Stack>
);

const AccountsPagePaper = styled(Paper)(({ theme }) => ({
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

export const AccountsPageTitle: React.FC<React.PropsWithChildren> = ({
    children,
}) => (
    <Typography variant="h3" sx={{ flex: 1 }}>
        {children}
    </Typography>
);

export const AccountsPageFooter: React.FC<React.PropsWithChildren> = ({
    children,
}) => (
    <Stack
        direction="row"
        sx={{
            mx: "4px",
            // Put the items to the side,
            justifyContent: "space-between",
            // Unless there is just one, in which case center it.
            "& :only-child": { marginInline: "auto" },
        }}
    >
        {children}
    </Stack>
);
