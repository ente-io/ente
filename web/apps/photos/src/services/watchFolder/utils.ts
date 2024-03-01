export const getParentFolderName = (filePath: string) => {
    const folderPath = filePath.substring(0, filePath.lastIndexOf("/"));
    const folderName = folderPath.substring(folderPath.lastIndexOf("/") + 1);
    return folderName;
};
