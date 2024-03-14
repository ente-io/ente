import * as htmlEntities from "html-entities";
import bpeVocabData from "./bpe_simple_vocab_16e6";
// import ftfy from "https://deno.land/x/ftfy_pyodide@v0.1.1/mod.js";

function ord(c: string) {
    return c.charCodeAt(0);
}
function range(start: number, stop?: number, step: number = 1) {
    if (stop === undefined) {
        stop = start;
        start = 0;
    }

    if ((step > 0 && start >= stop) || (step < 0 && start <= stop)) {
        return [];
    }

    const result: number[] = [];
    for (let i = start; step > 0 ? i < stop : i > stop; i += step) {
        result.push(i);
    }

    return result;
}

function bytesToUnicode() {
    const bs = [
        ...range(ord("!"), ord("~") + 1),
        ...range(ord("¡"), ord("¬") + 1),
        ...range(ord("®"), ord("ÿ") + 1),
    ];
    const cs = bs.slice(0);
    let n = 0;
    for (const b of range(2 ** 8)) {
        if (!bs.includes(b)) {
            bs.push(b);
            cs.push(2 ** 8 + n);
            n += 1;
        }
    }
    const csString = cs.map((n) => String.fromCharCode(n));
    return Object.fromEntries(bs.map((v, i) => [v, csString[i]]));
}

function getPairs(word: string | any[]) {
    const pairs: [string, string][] = [];
    let prevChar = word[0];
    for (const char of word.slice(1)) {
        pairs.push([prevChar, char]);
        prevChar = char;
    }
    return pairs;
}

function basicClean(text: string) {
    // text = ftfy.fix_text(text);
    text = htmlEntities.decode(htmlEntities.decode(text));
    return text.trim();
}

function whitespaceClean(text: string) {
    return text.replace(/\s+/g, " ").trim();
}

export default class {
    byteEncoder;
    byteDecoder: {
        [k: string]: number;
    };
    encoder;
    decoder: any;
    bpeRanks: any;
    cache: Record<string, string>;
    pat: RegExp;
    constructor() {
        this.byteEncoder = bytesToUnicode();
        this.byteDecoder = Object.fromEntries(
            Object.entries(this.byteEncoder).map(([k, v]) => [v, Number(k)]),
        );
        let merges = bpeVocabData.text.split("\n");
        merges = merges.slice(1, 49152 - 256 - 2 + 1);
        const mergedMerges = merges.map((merge) => merge.split(" "));
        // There was a bug related to the ordering of Python's .values() output. I'm lazy do I've just copy-pasted the Python output:
        let vocab = [
            "!",
            '"',
            "#",
            "$",
            "%",
            "&",
            "'",
            "(",
            ")",
            "*",
            "+",
            ",",
            "-",
            ".",
            "/",
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            ":",
            ";",
            "<",
            "=",
            ">",
            "?",
            "@",
            "A",
            "B",
            "C",
            "D",
            "E",
            "F",
            "G",
            "H",
            "I",
            "J",
            "K",
            "L",
            "M",
            "N",
            "O",
            "P",
            "Q",
            "R",
            "S",
            "T",
            "U",
            "V",
            "W",
            "X",
            "Y",
            "Z",
            "[",
            "\\",
            "]",
            "^",
            "_",
            "`",
            "a",
            "b",
            "c",
            "d",
            "e",
            "f",
            "g",
            "h",
            "i",
            "j",
            "k",
            "l",
            "m",
            "n",
            "o",
            "p",
            "q",
            "r",
            "s",
            "t",
            "u",
            "v",
            "w",
            "x",
            "y",
            "z",
            "{",
            "|",
            "}",
            "~",
            "¡",
            "¢",
            "£",
            "¤",
            "¥",
            "¦",
            "§",
            "¨",
            "©",
            "ª",
            "«",
            "¬",
            "®",
            "¯",
            "°",
            "±",
            "²",
            "³",
            "´",
            "µ",
            "¶",
            "·",
            "¸",
            "¹",
            "º",
            "»",
            "¼",
            "½",
            "¾",
            "¿",
            "À",
            "Á",
            "Â",
            "Ã",
            "Ä",
            "Å",
            "Æ",
            "Ç",
            "È",
            "É",
            "Ê",
            "Ë",
            "Ì",
            "Í",
            "Î",
            "Ï",
            "Ð",
            "Ñ",
            "Ò",
            "Ó",
            "Ô",
            "Õ",
            "Ö",
            "×",
            "Ø",
            "Ù",
            "Ú",
            "Û",
            "Ü",
            "Ý",
            "Þ",
            "ß",
            "à",
            "á",
            "â",
            "ã",
            "ä",
            "å",
            "æ",
            "ç",
            "è",
            "é",
            "ê",
            "ë",
            "ì",
            "í",
            "î",
            "ï",
            "ð",
            "ñ",
            "ò",
            "ó",
            "ô",
            "õ",
            "ö",
            "÷",
            "ø",
            "ù",
            "ú",
            "û",
            "ü",
            "ý",
            "þ",
            "ÿ",
            "Ā",
            "ā",
            "Ă",
            "ă",
            "Ą",
            "ą",
            "Ć",
            "ć",
            "Ĉ",
            "ĉ",
            "Ċ",
            "ċ",
            "Č",
            "č",
            "Ď",
            "ď",
            "Đ",
            "đ",
            "Ē",
            "ē",
            "Ĕ",
            "ĕ",
            "Ė",
            "ė",
            "Ę",
            "ę",
            "Ě",
            "ě",
            "Ĝ",
            "ĝ",
            "Ğ",
            "ğ",
            "Ġ",
            "ġ",
            "Ģ",
            "ģ",
            "Ĥ",
            "ĥ",
            "Ħ",
            "ħ",
            "Ĩ",
            "ĩ",
            "Ī",
            "ī",
            "Ĭ",
            "ĭ",
            "Į",
            "į",
            "İ",
            "ı",
            "Ĳ",
            "ĳ",
            "Ĵ",
            "ĵ",
            "Ķ",
            "ķ",
            "ĸ",
            "Ĺ",
            "ĺ",
            "Ļ",
            "ļ",
            "Ľ",
            "ľ",
            "Ŀ",
            "ŀ",
            "Ł",
            "ł",
            "Ń",
        ];
        vocab = [...vocab, ...vocab.map((v) => v + "</w>")];
        for (const merge of mergedMerges) {
            vocab.push(merge.join(""));
        }
        vocab.push("<|startoftext|>", "<|endoftext|>");
        this.encoder = Object.fromEntries(vocab.map((v, i) => [v, i]));
        this.decoder = Object.fromEntries(
            Object.entries(this.encoder).map(([k, v]) => [v, k]),
        );
        this.bpeRanks = Object.fromEntries(
            mergedMerges.map((v, i) => [v.join("·😎·"), i]),
        ); // ·😎· because js doesn't yet have tuples
        this.cache = {
            "<|startoftext|>": "<|startoftext|>",
            "<|endoftext|>": "<|endoftext|>",
        };
        this.pat =
            /<\|startoftext\|>|<\|endoftext\|>|'s|'t|'re|'ve|'m|'ll|'d|[\p{L}]+|[\p{N}]|[^\s\p{L}\p{N}]+/giu;
    }

    bpe(token: string) {
        if (this.cache[token] !== undefined) {
            return this.cache[token];
        }

        let word = [...token.slice(0, -1), token.slice(-1) + "</w>"];
        let pairs = getPairs(word);

        if (pairs.length === 0) {
            return token + "</w>";
        }

        // eslint-disable-next-line no-constant-condition
        while (1) {
            let bigram: [string, string] | null = null;
            let minRank = Infinity;
            for (const p of pairs) {
                const r = this.bpeRanks[p.join("·😎·")];
                if (r === undefined) continue;
                if (r < minRank) {
                    minRank = r;
                    bigram = p;
                }
            }

            if (bigram === null) {
                break;
            }

            const [first, second] = bigram;
            const newWord: string[] = [];
            let i = 0;
            while (i < word.length) {
                const j = word.indexOf(first, i);

                if (j === -1) {
                    newWord.push(...word.slice(i));
                    break;
                }

                newWord.push(...word.slice(i, j));
                i = j;

                if (
                    word[i] === first &&
                    i < word.length - 1 &&
                    word[i + 1] === second
                ) {
                    newWord.push(first + second);
                    i += 2;
                } else {
                    newWord.push(word[i]);
                    i += 1;
                }
            }
            word = newWord;
            if (word.length === 1) {
                break;
            } else {
                pairs = getPairs(word);
            }
        }
        const joinedWord = word.join(" ");
        this.cache[token] = joinedWord;
        return joinedWord;
    }

    encode(text: string) {
        const bpeTokens: number[] = [];
        text = whitespaceClean(basicClean(text)).toLowerCase();
        for (let token of [...text.matchAll(this.pat)].map((m) => m[0])) {
            token = [...token]
                .map((b) => this.byteEncoder[b.charCodeAt(0) as number])
                .join("");
            bpeTokens.push(
                ...this.bpe(token)
                    .split(" ")
                    .map((bpeToken: string) => this.encoder[bpeToken]),
            );
        }
        return bpeTokens;
    }

    // adds start and end token, and adds padding 0's and ensures it's 77 tokens long
    encodeForCLIP(text: string) {
        let tokens = this.encode(text);
        tokens.unshift(49406); // start token
        tokens = tokens.slice(0, 76);
        tokens.push(49407); // end token
        while (tokens.length < 77) tokens.push(0);
        return tokens;
    }

    decode(tokens: any[]) {
        let text = tokens
            .map((token: string | number) => this.decoder[token])
            .join("");
        text = [...text]
            .map((c) => this.byteDecoder[c])
            .map((v) => String.fromCharCode(v))
            .join("")
            .replace(/<\/w>/g, " ");
        return text;
    }
}
