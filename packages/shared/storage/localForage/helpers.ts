import localForage from '.';

export const clearFiles = async () => {
    await localForage.clear();
};
