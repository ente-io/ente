import { CenteredFill, Stack100vhCenter } from "@/base/components/containers";
import { FormPaper } from "@/base/components/FormPaper";
import { AppNavbar } from "@/base/components/Navbar";

/**
 * An ad-hoc component that abstracts the layout common to many of the pages
 * exported by the the accounts package.
 *
 * The layout is roughly:
 * - Set height to 100vh
 * - An app bar at the top
 * - Center a {@link FormPaper} in the rest of the space.
 * - The children passed to this component go within this {@link FormPaper}.
 */
export const AccountsPageContents: React.FC<React.PropsWithChildren> = ({
    children,
}) => (
    <Stack100vhCenter>
        <AppNavbar />
        <CenteredFill>
            <FormPaper>{children}</FormPaper>
        </CenteredFill>
    </Stack100vhCenter>
);
