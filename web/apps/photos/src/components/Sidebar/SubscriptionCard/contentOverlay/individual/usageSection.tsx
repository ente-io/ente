import { formattedStorageByteSize } from "@/new/photos/utils/units";
import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import { Box, Typography } from "@mui/material";
import { t } from "i18next";

import { Progressbar } from "../../styledComponents";

interface Iprops {
    usage: number;
    fileCount: number;
    storage: number;
}
export function IndividualUsageSection({ usage, storage, fileCount }: Iprops) {
    // [Note: Fallback translation for languages with multiple plurals]
    //
    // Languages like Polish and Arabian have multiple plural forms, and
    // currently i18n falls back to the base language translation instead of the
    // "_other" form if all the plural forms are not listed out.
    //
    // As a workaround, name the _other form as the unprefixed name. That is,
    // instead of calling the most general plural form as foo_count_other, call
    // it foo_count (To keep our heads straight, we adopt the convention that
    // all such pluralizable strings use the _count suffix, but that's not a
    // requirement from the library).
    return (
        <Box width="100%">
            <Progressbar value={Math.min((usage * 100) / storage, 100)} />
            <SpaceBetweenFlex
                sx={{
                    marginTop: 1.5,
                }}
            >
                <Typography variant="mini">{`${formattedStorageByteSize(
                    storage - usage,
                )} ${t("FREE")}`}</Typography>
                <Typography variant="mini" fontWeight={"bold"}>
                    {t("photos_count", { count: fileCount ?? 0 })}
                </Typography>
            </SpaceBetweenFlex>
        </Box>
    );
}
