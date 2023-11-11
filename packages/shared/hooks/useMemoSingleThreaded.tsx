import { useEffect, useRef, useState } from 'react';

export default function useMemoSingleThreaded<T>(
    fn: () => T | Promise<T>,
    deps: any[]
): T {
    const [result, setResult] = useState<T>(null);
    const updateInProgress = useRef(false);
    const updateRequired = useRef(false);
    useEffect(() => {
        const main = async () => {
            if (updateInProgress.current) {
                updateRequired.current = true;
                return;
            }
            updateInProgress.current = true;
            const result = fn();
            if (isPromise(result)) {
                const resultValue = await result;
                setResult(resultValue);
            } else {
                setResult(result);
            }
            updateInProgress.current = false;
            if (updateRequired.current) {
                updateRequired.current = false;
                setTimeout(main, 0);
            }
        };
        main();
    }, deps);

    return result;
}

function isPromise<T>(obj: T | Promise<T>): obj is Promise<T> {
    return obj && typeof (obj as any).then === 'function';
}
