import { ENTE_WEBSITE_LINK } from "@ente/shared/constants/urls";
import { Box } from "@mui/material";
import Link from "next/link";
import Ente from "../../components/icons/ente";

export function EnteLinkLogo() {
    return (
        <Link href={ENTE_WEBSITE_LINK}>
            <Box
                sx={(theme) => ({
                    ":hover": {
                        cursor: "pointer",
                        svg: {
                            fill: theme.colors.text.faint,
                        },
                    },
                })}
            >
                <Ente />
            </Box>
        </Link>
    );
}
