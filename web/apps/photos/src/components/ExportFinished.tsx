import { LinkButton } from "@/base/components/LinkButton";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { formattedNumber } from "@/base/i18n";
import { formattedDateTime } from "@/base/i18n-date";
import { EnteFile } from "@/media/file";
import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import { DialogActions, DialogContent, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { useState } from "react";
import ExportPendingList from "./ExportPendingList";

interface Props {
    pendingExports: EnteFile[];
    allCollectionsNameByID: Map<number, string>;
    onHide: () => void;
    lastExportTime: number;
    /** Called when the user presses the "Resync" button. */
    onResync: () => void;
}

export default function ExportFinished(props: Props) {
    const { lastExportTime } = props;

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
                            {t("pending_items")}
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
                            {lastExportTime
                                ? formattedDateTime(new Date(lastExportTime))
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
                allCollectionsNameByID={props.allCollectionsNameByID}
                isOpen={pendingFileListView}
                onClose={closePendingFileList}
            />
        </>
    );
}
