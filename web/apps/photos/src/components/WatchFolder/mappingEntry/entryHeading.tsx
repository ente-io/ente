import { FlexWrapper } from "@ente/shared/components/Container";
import { CircularProgress, Typography } from "@mui/material";
import { AppContext } from "pages/_app";
import { useContext } from "react";
import watchFolderService from "services/watchFolder/watchFolderService";
import { WatchMapping } from "types/watchFolder";

interface Iprops {
    mapping: WatchMapping;
}

export function EntryHeading({ mapping }: Iprops) {
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
