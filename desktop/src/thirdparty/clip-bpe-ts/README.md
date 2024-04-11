# CLIP Byte Pair Encoding JavaScript Port

A JavaScript port of
[OpenAI's CLIP byte-pair-encoding tokenizer](https://github.com/openai/CLIP/blob/3bee28119e6b28e75b82b811b87b56935314e6a5/clip/simple_tokenizer.py).

```js
import Tokenizer from "https://deno.land/x/clip_bpe@v0.0.6/mod.js";
let t = new Tokenizer();

t.encode("hello"); // [3306]
t.encode("magnificent"); // [10724]
t.encode("magnificently"); // [9725, 2922]
t.decode(t.encode("HELLO")); // "hello "
t.decode(t.encode("abc123")); // "abc 1 2 3 "
t.decode(st.encode("let's see here")); // "let 's see here "
t.encode("hello world!"); // [3306, 1002, 256]

// to encode for CLIP (trims to maximum of 77 tokens and adds start and end token, and pads with zeros if less than 77 tokens):
t.encodeForCLIP("hello world!"); // [49406,3306,1002,256,49407,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
```

This encoder/decoder behaves differently to the the GPT-2/3 tokenizer
(JavaScript version of that
[here](https://github.com/latitudegames/GPT-3-Encoder)). For example, it doesn't
preserve capital letters, as shown above.

The
[Python version](https://github.com/openai/CLIP/blob/3bee28119e6b28e75b82b811b87b56935314e6a5/clip/simple_tokenizer.py)
of this tokenizer uses the `ftfy` module to clean up the text before encoding
it. I didn't include that module by default because currently the only version
available in JavaScript is
[this one](https://github.com/josephrocca/ftfy-pyodide), which requires
importing a full Python runtime as a WebAssembly module. If you want the `ftfy`
cleaning, just import it and clean your text with it before passing it to the
`.encode()` method.

# License

To the extent that there is any original work in this repo, it is MIT Licensed,
just like [openai/CLIP](https://github.com/openai/CLIP).
