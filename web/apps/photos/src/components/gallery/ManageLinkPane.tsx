import { PublicShare } from "@/components/Collections/CollectionShare";
import type { RemotePullOpts } from "@/components/gallery";
import { Stack, Typography } from "@mui/material";
import { CenteredFill } from "ente-base/components/containers";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import type { Collection } from "ente-media/collection";
import { t } from "i18next";

interface ManageLinkPaneProps {
    collection: Collection | undefined;
    loading: boolean;
    onRemotePull: (opts?: RemotePullOpts) => Promise<void>;
    onLinkRemoved: (collectionID: number) => void;
}

export const ManageLinkPane = ({
    collection,
    loading,
    ...rest
}: ManageLinkPaneProps) => {
    if (loading)
        return (
            <CenteredFill>
                <ActivityIndicator />
            </CenteredFill>
        );
    if (!collection) {
        return (
            <CenteredFill>
                <Stack sx={{ gap: 1, p: 3, textAlign: "center" }}>
                    <Typography variant="h3">
                        {t("links_empty_title")}
                    </Typography>
                    <Typography sx={{ color: "text.muted" }}>
                        {t("links_empty_description")}
                    </Typography>
                </Stack>
            </CenteredFill>
        );
    }
    return (
        <PublicShare
            key={collection.id}
            inline
            collection={collection}
            {...rest}
        />
    );
};
