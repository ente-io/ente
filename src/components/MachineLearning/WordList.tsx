import Box from '@mui/material/Box';
import { Chip } from 'components/Chip';
import { Legend } from 'components/PhotoViewer/styledComponents/Legend';
import React, { useState, useEffect } from 'react';
import { EnteFile } from 'types/file';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import constants from 'utils/strings/constants';

export function WordList(props: { file: EnteFile; updateMLDataIndex: number }) {
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
    }, [props.file, props.updateMLDataIndex]);

    if (words.length === 0) return <></>;

    return (
        <>
            <Legend>{constants.TEXT}</Legend>
            <Box
                display={'flex'}
                gap={1}
                flexWrap="wrap"
                justifyContent={'flex-start'}
                alignItems={'flex-start'}>
                {words.map((word) => (
                    <Chip key={word}>{word}</Chip>
                ))}
            </Box>
        </>
    );
}
