import Box from '@mui/material/Box';
import { Chip } from 'components/Chip';
import { Legend } from 'components/PhotoViewer/styledComponents/Legend';
import React, { useState, useEffect } from 'react';
import { EnteFile } from 'types/file';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import constants from 'utils/strings/constants';

export function ObjectLabelList(props: {
    file: EnteFile;
    updateMLDataIndex: number;
}) {
    const [objects, setObjects] = useState<Array<string>>([]);
    useEffect(() => {
        let didCancel = false;
        const main = async () => {
            const things = await mlIDbStorage.getAllThingsMap();
            const uniqueObjectNames = [
                ...new Set(
                    (things.get(props.file.id) ?? []).map(
                        (object) => object.detection.class
                    )
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
            <Legend sx={{ pb: 1, display: 'block' }}>
                {constants.OBJECTS}
            </Legend>
            <Box
                display={'flex'}
                gap={1}
                flexWrap="wrap"
                justifyContent={'flex-start'}
                alignItems={'flex-start'}>
                {objects.map((object) => (
                    <Chip key={object}>{object}</Chip>
                ))}
            </Box>
        </div>
    );
}
