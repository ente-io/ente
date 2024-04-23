/**
 * Wait for {@link ms} milliseconds
 *
 * This function is a promisified `setTimeout`. It returns a promise that
 * resolves after {@link ms} milliseconds.
 */
export const wait = (ms: number) =>
    new Promise((resolve) => setTimeout(resolve, ms));

export function downloadAsFile(filename: string, content: string) {
    const file = new Blob([content], {
        type: "text/plain",
    });
    const fileURL = URL.createObjectURL(file);
    downloadUsingAnchor(fileURL, filename);
}

export function downloadUsingAnchor(link: string, name: string) {
    const a = document.createElement("a");
    a.style.display = "none";
    a.href = link;
    a.download = name;
    document.body.appendChild(a);
    a.click();
    URL.revokeObjectURL(link);
    a.remove();
}

export function isPromise<T>(obj: T | Promise<T>): obj is Promise<T> {
    return obj && typeof (obj as any).then === "function";
}

export async function retryAsyncFunction<T>(
    request: (abort?: () => void) => Promise<T>,
    waitTimeBeforeNextTry?: number[],
): Promise<T> {
    if (!waitTimeBeforeNextTry) waitTimeBeforeNextTry = [2000, 5000, 10000];

    for (
        let attemptNumber = 0;
        attemptNumber <= waitTimeBeforeNextTry.length;
        attemptNumber++
    ) {
        try {
            const resp = await request();
            return resp;
        } catch (e) {
            if (attemptNumber === waitTimeBeforeNextTry.length) {
                throw e;
            }
            await wait(waitTimeBeforeNextTry[attemptNumber]);
        }
    }
}

/**
 * Await the given {@link promise} for {@link timeoutMS} milliseconds. If it
 * does not resolve within {@link timeoutMS}, then reject with a timeout error.
 */
export const withTimeout = async <T>(promise: Promise<T>, ms: number) => {
    let timeoutId: ReturnType<typeof setTimeout>;
    const rejectOnTimeout = new Promise<T>((_, reject) => {
        timeoutId = setTimeout(
            () => reject(new Error("Operation timed out")),
            ms,
        );
    });
    const promiseAndCancelTimeout = async () => {
        const result = await promise;
        clearTimeout(timeoutId);
        return result;
    };
    return Promise.race([promiseAndCancelTimeout(), rejectOnTimeout]);
};
