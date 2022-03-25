export const getReadableSizeFromBytes = (bytes: number) => {
    const sizes = ['B', 'KB', 'MB', 'GB'];
    let currSize = 0;
    while (bytes >= 1024 && currSize < sizes.length) {
        bytes /= 1024;
        currSize++;
    }
    return `${bytes.toFixed(2)} ${sizes[currSize]}`;
};
