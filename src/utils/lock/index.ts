import { Lock } from 'types/lock';

export function newLock(): Lock {
    let resolver: () => void = null;
    const wait = new Promise<void>((resolve) => {
        resolver = resolve;
    });
    return {
        wait,
        unlock: () => {
            resolver();
        },
    };
}
