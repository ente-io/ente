export const readAsDataURL = (blob) =>
    new Promise<string>((resolve, reject) => {
        const fileReader = new FileReader();
        fileReader.onload = () => resolve(fileReader.result as string);
        fileReader.onerror = () => reject(fileReader.error);
        fileReader.readAsDataURL(blob);
    });

export const readAsText = (blob) =>
    new Promise<string>((resolve, reject) => {
        const fileReader = new FileReader();
        fileReader.onload = () => resolve(fileReader.result as string);
        fileReader.onerror = () => reject(fileReader.error);
        fileReader.readAsText(blob);
    });
