import React, { useState, useEffect } from 'react';
import objectService from 'services/machineLearning/objectService';
import { EnteFile } from 'types/file';
import { Object } from 'types/machineLearning';

export function ObjectLabelList(props: { file: EnteFile }) {
    const [objects, setObjects] = useState<Array<Object>>([]);
    useEffect(() => {
        let didCancel = false;
        const main = async () => {
            const objects = await objectService.getAllSyncedObjectsMap();
            !didCancel && setObjects(objects.get(props.file.id));
        };
        main();
        return () => {
            didCancel = true;
        };
    }, [props.file]);

    return (
        <div>
            {objects.map((object) => (
                <span style={{ margin: '0 2px ' }} key={object.id}>
                    {object.detection.class}
                </span>
            ))}
        </div>
    );
}
