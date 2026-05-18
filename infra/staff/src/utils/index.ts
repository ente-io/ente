export const formatUsageToGB = (usage: number): string => {
    const usageInGB = (usage / (1024 * 1024 * 1024)).toFixed(2);
    return `${usageInGB} GB`;
};
