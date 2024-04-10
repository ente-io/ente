import { t } from "i18next";
import { useContext } from "react";

import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { Typography } from "@mui/material";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import { NoStyleAnchor } from "components/pages/sharedAlbum/GoToEnte";
import isElectron from "is-electron";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import exportService from "services/export";
import { openLink } from "utils/common";
import { getDownloadAppMessage } from "utils/ui";

export default function HelpSection() {
    const { setDialogMessage } = useContext(AppContext);
    const { openExportModal } = useContext(GalleryContext);

    const openRoadmap = () =>
        openLink("https://github.com/ente-io/ente/discussions", true);

    const contactSupport = () => openLink("mailto:support@ente.io", true);

    function openExport() {
        if (isElectron()) {
            openExportModal();
        } else {
            setDialogMessage(getDownloadAppMessage());
        }
    }

    return (
        <>
            <EnteMenuItem
                onClick={openRoadmap}
                label={t("REQUEST_FEATURE")}
                variant="secondary"
            />
            <EnteMenuItem
                onClick={contactSupport}
                labelComponent={
                    <NoStyleAnchor href="mailto:support@ente.io">
                        <Typography fontWeight={"bold"}>
                            {t("SUPPORT")}
                        </Typography>
                    </NoStyleAnchor>
                }
                variant="secondary"
            />
            <EnteMenuItem
                onClick={openExport}
                label={t("EXPORT")}
                endIcon={
                    exportService.isExportInProgress() && (
                        <EnteSpinner size="20px" />
                    )
                }
                variant="secondary"
            />
        </>
    );
}
