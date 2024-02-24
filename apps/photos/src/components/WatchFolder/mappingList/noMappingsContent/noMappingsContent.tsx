import { Stack, Typography } from "@mui/material";
import { t } from "i18next";

import { FlexWrapper } from "@ente/shared/components/Container";
import { NoMappingsContainer } from "../../styledComponents";
import { CheckmarkIcon } from "./checkmarkIcon";

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
