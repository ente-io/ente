import Box from "@mui/material/Box";
import { Chip } from "components/Chip";
import { Legend } from "components/PhotoViewer/styledComponents/Legend";
import { t } from "i18next";
import { useEffect, useState } from "react";
import { EnteFile } from "types/file";
import mlIDbStorage from "utils/storage/mlIDbStorage";

export function ObjectLabelList(props: {
    file: EnteFile;
    updateMLDataIndex: number;
}) {
    const [objects, setObjects] = useState<Array<string>>([]);
    useEffect(() => {
        let didCancel = false;
        const main = async () => {
            const objects = await mlIDbStorage.getAllObjectsMap();
            const uniqueObjectNames = [
                ...new Set(
                    (objects.get(props.file.id) ?? []).map(
                        (object) => object.detection.class,
                    ),
                ),
            ];
            !didCancel && setObjects(uniqueObjectNames);
        };
        main();
        return () => {
            didCancel = true;
        };
    }, [props.file, props.updateMLDataIndex]);

    if (objects.length === 0) return <></>;

    return (
        <div>
            <Legend sx={{ pb: 1, display: "block" }}>{t("OBJECTS")}</Legend>
            <Box
                display={"flex"}
                gap={1}
                flexWrap="wrap"
                justifyContent={"flex-start"}
                alignItems={"flex-start"}
            >
                {objects.map((object) => (
                    <Chip key={object}>{object}</Chip>
                ))}
            </Box>
        </div>
    );
}
