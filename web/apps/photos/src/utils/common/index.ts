export const preloadImage = (imgBasePath: string) => {
    const srcSet = [];
    for (let i = 1; i <= 3; i++) {
        srcSet.push(`${imgBasePath}/${i}x.png ${i}x`);
    }
    new Image().srcset = srcSet.join(",");
};

export function openLink(href: string, newTab?: boolean) {
    const a = document.createElement("a");
    a.href = href;
    if (newTab) {
        a.target = "_blank";
    }
    a.rel = "noreferrer noopener";
    a.click();
}

export function isClipboardItemPresent() {
    return typeof ClipboardItem !== "undefined";
}

export function batch<T>(arr: T[], batchSize: number): T[][] {
    const batches: T[][] = [];
    for (let i = 0; i < arr.length; i += batchSize) {
        batches.push(arr.slice(i, i + batchSize));
    }
    return batches;
}
