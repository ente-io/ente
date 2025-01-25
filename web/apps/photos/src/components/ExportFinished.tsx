import { LinkButton } from "@/base/components/LinkButton";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { formattedNumber } from "@/base/i18n";
import { EnteFile } from "@/media/file";
import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import { formatDateTime } from "@ente/shared/time/format";
import { DialogActions, DialogContent, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { useState } from "react";
import ExportPendingList from "./ExportPendingList";

interface Props {
    pendingExports: EnteFile[];
    collectionNameMap: Map<number, string>;
    onHide: () => void;
    lastExportTime: number;
    /** Called when the user presses the "Resync" button. */
    onResync: () => void;
}

export default function ExportFinished(props: Props) {
    const [pendingFileListView, setPendingFileListView] =
        useState<boolean>(false);

    const openPendingFileList = () => {
        setPendingFileListView(true);
    };

    const closePendingFileList = () => {
        setPendingFileListView(false);
    };
    return (
        <>
            <DialogContent>
                <Stack sx={{ pr: 2 }}>
                    <SpaceBetweenFlex minHeight={"48px"}>
                        <Typography sx={{ color: "text.muted" }}>
                            {t("PENDING_ITEMS")}
                        </Typography>
                        {props.pendingExports.length ? (
                            <LinkButton onClick={openPendingFileList}>
                                {formattedNumber(props.pendingExports.length)}
                            </LinkButton>
                        ) : (
                            <Typography>
                                {formattedNumber(props.pendingExports.length)}
                            </Typography>
                        )}
                    </SpaceBetweenFlex>
                    <SpaceBetweenFlex minHeight={"48px"}>
                        <Typography sx={{ color: "text.muted" }}>
                            {t("last_export_time")}
                        </Typography>
                        <Typography>
                            {props.lastExportTime
                                ? formatDateTime(props.lastExportTime)
                                : t("never")}
                        </Typography>
                    </SpaceBetweenFlex>
                </Stack>
            </DialogContent>
            <DialogActions>
                <FocusVisibleButton
                    fullWidth
                    color="secondary"
                    onClick={props.onHide}
                >
                    {t("close")}
                </FocusVisibleButton>
                <FocusVisibleButton fullWidth onClick={props.onResync}>
                    {t("export_again")}
                </FocusVisibleButton>
            </DialogActions>
            <ExportPendingList
                pendingExports={props.pendingExports}
                collectionNameMap={props.collectionNameMap}
                isOpen={pendingFileListView}
                onClose={closePendingFileList}
            />
        </>
    );
}
