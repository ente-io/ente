import { Chip } from 'components/pages/gallery/Collections';
import React, { useState, useEffect } from 'react';
import { EnteFile } from 'types/file';
import mlIDbStorage from 'utils/storage/mlIDbStorage';

export function WordList(props: { file: EnteFile }) {
    const [words, setWords] = useState<string[]>([]);
    useEffect(() => {
        let didCancel = false;
        const main = async () => {
            const texts = await mlIDbStorage.getAllTextMap();
            const uniqueDetectedWords = [
                ...new Set(
                    (texts.get(props.file.id) ?? []).map(
                        (text) => text.detection.word
                    )
                ),
            ];

            !didCancel && setWords(uniqueDetectedWords);
        };
        main();
        return () => {
            didCancel = true;
        };
    }, [props.file]);

    return (
        <div>
            {words.map((object) => (
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
