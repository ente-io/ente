export function prettyPrintExif(data: Object) {
    let a;

    let strPretty = '';
    for (a in data) {
        if (typeof data[a] === 'object') {
            if (data[a] instanceof Number) {
                strPretty +=
                    a +
                    ' : ' +
                    data[a] +
                    ' [' +
                    data[a].numerator +
                    '/' +
                    data[a].denominator +
                    ']\r\n';
            } else {
                strPretty += a + ' : [' + data[a].length + ' values]\r\n';
            }
        } else {
            strPretty += a + ' : ' + data[a] + '\r\n';
        }
    }
    return strPretty;
}
