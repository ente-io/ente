import { CodeBlock } from 'components/CodeBlock';
import React, { useState, useEffect } from 'react';
import { EnteFile } from 'types/file';
import mlIDbStorage from 'utils/storage/mlIDbStorage';

export function TextDetection(props: { file: EnteFile }) {
    const [text, setText] = useState<string>(null);
    useEffect(() => {
        let didCancel = false;
        const main = async () => {
            const text = await mlIDbStorage.getAllTextMap();
            const detectedWords = text.get(props.file.id)?.detection.data.text;

            !didCancel && setText(detectedWords);
        };
        main();
        return () => {
            didCancel = true;
        };
    }, [props.file]);

    return <CodeBlock code={text} />;
}
