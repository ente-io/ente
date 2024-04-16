import {
    FlexWrapper,
    HorizontalFlex,
    SpaceBetweenFlex,
} from "@ente/shared/components/Container";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import DoNotDisturbOutlinedIcon from "@mui/icons-material/DoNotDisturbOutlined";
import FolderCopyOutlinedIcon from "@mui/icons-material/FolderCopyOutlined";
import FolderOpenIcon from "@mui/icons-material/FolderOpen";
import MoreHorizIcon from "@mui/icons-material/MoreHoriz";
import { CircularProgress, Tooltip, Typography } from "@mui/material";
import { UPLOAD_STRATEGY } from "constants/upload";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import React, { useContext } from "react";
import watchFolderService from "services/watchFolder/watchFolderService";
import { WatchMapping } from "types/watchFolder";
import { EntryContainer } from "../styledComponents";
import { EntryHeading } from "./entryHeading";
import MappingEntryOptions from "./mappingEntryOptions";

interface MappingEntryProps {
    mapping: WatchMapping;
    handleRemoveMapping: (mapping: WatchMapping) => void;
}

export function MappingEntry({
    mapping,
    handleRemoveMapping,
}: MappingEntryProps) {
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

interface EntryHeadingProps {
    mapping: WatchMapping;
}

export function EntryHeading({ mapping }: EntryHeadingProps) {
    const appContext = useContext(AppContext);
    return (
        <FlexWrapper gap={1}>
            <Typography>{mapping.rootFolderName}</Typography>
            {appContext.isFolderSyncRunning &&
                watchFolderService.isMappingSyncInProgress(mapping) && (
                    <CircularProgress size={12} />
                )}
        </FlexWrapper>
    );
}

interface MappingEntryOptionsProps {
    confirmStopWatching: () => void;
}

export default function MappingEntryOptions({
    confirmStopWatching,
}: MappingEntryOptionsProps) {
    return (
        <OverflowMenu
            menuPaperProps={{
                sx: {
                    backgroundColor: (theme) =>
                        theme.colors.background.elevated2,
                },
            }}
            ariaControls={"watch-mapping-option"}
            triggerButtonIcon={<MoreHorizIcon />}
        >
            <OverflowMenuOption
                color="critical"
                onClick={confirmStopWatching}
                startIcon={<DoNotDisturbOutlinedIcon />}
            >
                {t("STOP_WATCHING")}
            </OverflowMenuOption>
        </OverflowMenu>
    );
}
