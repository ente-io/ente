import { bytesInGB, formattedStorageByteSize } from "@/new/photos/utils/units";
import { Box, Typography, styled } from "@mui/material";
import { t } from "i18next";

const MobileSmallBox = styled(Box)`
    display: none;
    @media (max-width: 359px) {
        display: block;
    }
`;

const DefaultBox = styled(Box)`
    display: none;
    @media (min-width: 360px) {
        display: block;
    }
`;
interface Iprops {
    usage: number;
    storage: number;
}
export default function StorageSection({ usage, storage }: Iprops) {
    return (
        <Box width="100%">
            <Typography variant="small" color={"text.muted"}>
                {t("STORAGE")}
            </Typography>
            <DefaultBox>
                <Typography
                    fontWeight={"bold"}
                    sx={{ fontSize: "24px", lineHeight: "30px" }}
                >
                    {`${formattedStorageByteSize(usage, { round: true })} ${t(
                        "OF",
                    )} ${formattedStorageByteSize(storage)} ${t("USED")}`}
                </Typography>
            </DefaultBox>
            <MobileSmallBox>
                <Typography
                    fontWeight={"bold"}
                    sx={{ fontSize: "24px", lineHeight: "30px" }}
                >
                    {`${bytesInGB(usage)} /  ${bytesInGB(storage)} ${t("storage_unit.gb")} ${t("USED")}`}
                </Typography>
            </MobileSmallBox>
        </Box>
    );
}
