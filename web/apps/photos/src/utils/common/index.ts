export function batch<T>(arr: T[], batchSize: number): T[][] {
    const batches: T[][] = [];
    for (let i = 0; i < arr.length; i += batchSize) {
        batches.push(arr.slice(i, i + batchSize));
    }
    return batches;
}
