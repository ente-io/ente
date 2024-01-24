import { useEffect, useRef } from 'react';
import { isPromise } from '../utils';

export default function useEffectSingleThreaded(
    fn: (deps) => void | Promise<void>,
    deps: any[]
): void {
    const updateInProgress = useRef(false);
    const nextRequestDepsRef = useRef<any[]>(null);
    useEffect(() => {
        const main = async (deps) => {
            if (updateInProgress.current) {
                nextRequestDepsRef.current = deps;
                return;
            }
            updateInProgress.current = true;
            const result = fn(deps);
            if (isPromise(result)) {
                await result;
            }
            updateInProgress.current = false;
            if (nextRequestDepsRef.current) {
                const deps = nextRequestDepsRef.current;
                nextRequestDepsRef.current = null;
                setTimeout(() => main(deps), 0);
            }
        };
        main(deps);
    }, deps);
}
