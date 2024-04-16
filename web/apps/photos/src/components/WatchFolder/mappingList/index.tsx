import { FlexWrapper } from "@ente/shared/components/Container";
import CheckIcon from "@mui/icons-material/Check";
import { Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { WatchMapping } from "types/watchFolder";
import { NoMappingsContainer } from "../../styledComponents";
import { MappingEntry } from "../mappingEntry";
import { MappingsContainer } from "../styledComponents";
import { NoMappingsContent } from "./noMappingsContent/noMappingsContent";

interface MappingListProps {
    mappings: WatchMapping[];
    handleRemoveWatchMapping: (value: WatchMapping) => void;
}

export function MappingList({
    mappings,
    handleRemoveWatchMapping,
}: MappingListProps) {
    return mappings.length === 0 ? (
        <NoMappingsContent />
    ) : (
        <MappingsContainer>
            {mappings.map((mapping) => {
                return (
                    <MappingEntry
                        key={mapping.rootFolderName}
                        mapping={mapping}
                        handleRemoveMapping={handleRemoveWatchMapping}
                    />
                );
            })}
        </MappingsContainer>
    );
}

export function NoMappingsContent() {
    return (
        <NoMappingsContainer>
            <Stack spacing={1}>
                <Typography variant="large" fontWeight={"bold"}>
                    {t("NO_FOLDERS_ADDED")}
                </Typography>
                <Typography py={0.5} variant={"small"} color="text.muted">
                    {t("FOLDERS_AUTOMATICALLY_MONITORED")}
                </Typography>
                <Typography variant={"small"} color="text.muted">
                    <FlexWrapper gap={1}>
                        <CheckmarkIcon />
                        {t("UPLOAD_NEW_FILES_TO_ENTE")}
                    </FlexWrapper>
                </Typography>
                <Typography variant={"small"} color="text.muted">
                    <FlexWrapper gap={1}>
                        <CheckmarkIcon />
                        {t("REMOVE_DELETED_FILES_FROM_ENTE")}
                    </FlexWrapper>
                </Typography>
            </Stack>
        </NoMappingsContainer>
    );
}

export function CheckmarkIcon() {
    return (
        <CheckIcon
            fontSize="small"
            sx={{
                display: "inline",
                fontSize: "15px",

                color: (theme) => theme.palette.secondary.main,
            }}
        />
    );
}
