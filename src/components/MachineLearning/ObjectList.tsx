import { Chip } from 'components/pages/gallery/Collections';
import React, { useState, useEffect } from 'react';
import { EnteFile } from 'types/file';
import mlIDbStorage from 'utils/storage/mlIDbStorage';

export function ObjectLabelList(props: { file: EnteFile }) {
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
    }, [props.file]);

    return (
        <div>
            {objects.map((object) => (
                <Chip
                    active={true}
                    style={{
                        paddingLeft: 0,
                        padding: '5px 10px',
                        cursor: 'default',
                    }}
                    key={object}>
                    {object}
                </Chip>
            ))}
        </div>
    );
}
