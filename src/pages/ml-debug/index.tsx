import React from 'react';
import dynamic from 'next/dynamic';

const MLDebugWithNoSSR = dynamic(() => import('components/MlDebug'), {
    ssr: false,
});

export default function MLDebug() {
    return (
        <div>
            <MLDebugWithNoSSR></MLDebugWithNoSSR>
        </div>
    );
}
