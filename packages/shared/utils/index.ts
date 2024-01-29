export async function sleep(time: number) {
    await new Promise((resolve) => {
        setTimeout(() => resolve(null), time);
    });
}

export function downloadAsFile(filename: string, content: string) {
    const file = new Blob([content], {
        type: 'text/plain',
    });
    const fileURL = URL.createObjectURL(file);
    downloadUsingAnchor(fileURL, filename);
}

export function downloadUsingAnchor(link: string, name: string) {
    const a = document.createElement('a');
    a.style.display = 'none';
    a.href = link;
    a.download = name;
    document.body.appendChild(a);
    a.click();
    URL.revokeObjectURL(link);
    a.remove();
}

export function isPromise<T>(obj: T | Promise<T>): obj is Promise<T> {
    return obj && typeof (obj as any).then === 'function';
}
