import {
    HorizontalFlex,
    SpaceBetweenFlex,
} from "@ente/shared/components/Container";
import FolderCopyOutlinedIcon from "@mui/icons-material/FolderCopyOutlined";
import FolderOpenIcon from "@mui/icons-material/FolderOpen";
import { Tooltip, Typography } from "@mui/material";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import React from "react";
import { WatchMapping } from "types/watchFolder";
import { EntryContainer } from "../styledComponents";

import { UPLOAD_STRATEGY } from "constants/upload";
import { EntryHeading } from "./entryHeading";
import MappingEntryOptions from "./mappingEntryOptions";

interface Iprops {
    mapping: WatchMapping;
    handleRemoveMapping: (mapping: WatchMapping) => void;
}

export function MappingEntry({ mapping, handleRemoveMapping }: Iprops) {
    const appContext = React.useContext(AppContext);

    const stopWatching = () => {
        handleRemoveMapping(mapping);
    };

    const confirmStopWatching = () => {
        appContext.setDialogMessage({
            title: t("STOP_WATCHING_FOLDER"),
            content: t("STOP_WATCHING_DIALOG_MESSAGE"),
            close: {
                text: t("CANCEL"),
                variant: "secondary",
            },
            proceed: {
                action: stopWatching,
                text: t("YES_STOP"),
                variant: "critical",
            },
        });
    };

    return (
        <SpaceBetweenFlex>
            <HorizontalFlex>
                {mapping &&
                mapping.uploadStrategy === UPLOAD_STRATEGY.SINGLE_COLLECTION ? (
                    <Tooltip title={t("UPLOADED_TO_SINGLE_COLLECTION")}>
                        <FolderOpenIcon />
                    </Tooltip>
                ) : (
                    <Tooltip title={t("UPLOADED_TO_SEPARATE_COLLECTIONS")}>
                        <FolderCopyOutlinedIcon />
                    </Tooltip>
                )}
                <EntryContainer>
                    <EntryHeading mapping={mapping} />
                    <Typography color="text.muted" variant="small">
                        {mapping.folderPath}
                    </Typography>
                </EntryContainer>
            </HorizontalFlex>
            <MappingEntryOptions confirmStopWatching={confirmStopWatching} />
        </SpaceBetweenFlex>
    );
}
