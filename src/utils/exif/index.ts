export function prettyPrintExif(exifData: Object) {
    let strPretty = '';
    for (const [tagName, tagValue] of Object.entries(exifData)) {
        if (tagValue instanceof Uint8Array) {
            strPretty += tagName + ' : ' + '[' + tagValue + ']' + '\r\n';
        } else if (tagValue instanceof Date) {
            strPretty += tagName + ' : ' + tagValue.toDateString() + '\r\n';
        } else {
            strPretty += tagName + ' : ' + tagValue + '\r\n';
        }
    }
    return strPretty;
}
