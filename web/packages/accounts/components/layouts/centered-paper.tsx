import { CenteredFill } from "@/base/components/containers";
import { EnteLogo } from "@/base/components/EnteLogo";
import { NavbarBaseNormalFlow } from "@/base/components/Navbar";
import { wipTheme } from "@/base/components/utils/theme";
import { Paper, Stack, styled, Typography } from "@mui/material";

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
    <Stack sx={{ minHeight: "100svh" }}>
        <NavbarBaseNormalFlow
            sx={[
                (theme) =>
                    theme.applyStyles("light", {
                        borderBottomColor: wipTheme ? "stroke.base" : "divider",
                    }),
            ]}
        >
            <EnteLogo />
        </NavbarBaseNormalFlow>
        <CenteredFill
            sx={[
                { bgcolor: wipTheme ? "accent.main" : "background.default" },
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
    padding: theme.spacing(4, 2),
    width: "min(375px, 80vw)",
    minHeight: "375px",
    display: "flex",
    flexDirection: "column",
    gap: theme.spacing(4),
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
