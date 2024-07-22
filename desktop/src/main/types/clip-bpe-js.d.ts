/**
 * Types for [clip-bpe-js](https://github.com/josephrocca/clip-bpe-js).
 *
 * Non exhaustive, only the function we need.
 */
declare module "clip-bpe-js" {
    class Tokenizer {
        encodeForCLIP(text: string): number[];
    }
}
