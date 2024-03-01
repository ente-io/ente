import { useEffect, useRef } from "react";
import { isPromise } from "../utils";

// useEffectSingleThreaded is a useEffect that will only run one at a time, and will
// caches the latest deps of requests that come in while it is running, and will
// run that after the current run is complete.
export default function useEffectSingleThreaded(
    fn: (deps) => void | Promise<void>,
    deps: any[],
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
