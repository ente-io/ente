

/*--------------------------------------------------------------------------------------------

    MIT license.

    Copyright 2017 Aaron Flin

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to
    deal in the Software without restriction, including without limitation the
    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.


----------------------------------------------------------------------------------------------*/
import forge from 'node-forge';

//start collecting random data for forge RNG
var d = new Date();

if (typeof document !== 'undefined') {
    forge.random.collect(d.getTime(), 32);
    //in normal version, we can get the mouse movements and add that as random data.
    document.onmousemove = function (e) {
        forge.random.collectInt(e.clientX, 16);
        forge.random.collectInt(e.clientY, 16);
    };
}



export var aescrypt = (function () {

    var b2h = forge.util.bytesToHex;

    function a2h(a) {
        return forge.util.bytesToHex(arrayToString(a));
    }

    var toType = function (obj) {
        return ({}).toString.call(obj).match(/\s([a-zA-Z0-9]+)/)[1].toLowerCase();
    }

    /* copy string or uint8array into a uint8array 
        start is where in output array to start copying
        max is max bytes to copy from input string/array
    	
        does not check if a is big enough to take s
    */

    function copyToArray(s, a, start, max) {
        if (max === undefined) max = s.length;
        if (start === undefined) start = 0;
        var t = toType(s);

        if (t == "arraybuffer") {
            s = new Uint8Array(s);
            t = 'uint8array';
        }

        switch (t) {
            case 'array':
            case 'uint8array':
                //for (var i=0; i<max;i++)
                //      a[i+start]=s[i];
                // not much of an improvement using .set(), if any at all
                if (max >= s.length) {
                    a.set(s, start);
                    return s.length;
                } else if (t == 'array') {
                    a.set(s.slice(0, max), start);
                } else {
                    a.set(s.subarray(0, max), start);
                }
                return max;
            case 'string':
                for (var i = 0; i < max; i++)
                    a[i + start] = s.charCodeAt(i);
                return i;
            default:
                return 0;
        }
    }


    /* convert a uint8array or arraybuffer to a string */
    function arrayToString(array) {
        var ret = "";
        if (toType(array) == 'arraybuffer')
            array = new Uint8Array(array);
        return String.fromCharCode.apply(null, array);
    }

    function toU8(data, nostrings) {
        switch (toType(data)) {
            case 'uint8array':
                return data;
            case 'arraybuffer':
                return (new Uint8Array(data));
            case 'string':
                if (nostrings) return;
            //no break
            case 'array':
                // is this the best way to do this, given encfile could be large?
                var x = new Uint8Array(data.length);
                copyToArray(data, x, 0);
                return x;
            default:
                break;
        }
    }

    function isblank(a, start, len) {
        var end = start + len;
        for (var i = start; i < end; i++)
            if (a[i] != 0) return false;
        return true;
    }

    function to16(str) {
        var out, i, len, c, c2;
        var char2, char3;

        out = "";
        len = str.length;
        i = 0;
        while (i < len) {
            c = str.charCodeAt(i++);
            c2 = c >>> 8;
            c = c & 0xFF;
            out += String.fromCharCode(c);
            out += String.fromCharCode(c2);
        }
        return out;
    }

    function ivpasstokey(iv, pass) {
        var hashbuf = new Uint8Array(32);
        var hashstr, hashstr2;
        var p = to16(pass);
        copyToArray(iv, hashbuf, 0);
        hashstr = arrayToString(hashbuf);
        hashstr2 = hashstr;
        // do this outside the loop, its expensive, and many times more expensive in chrome than firefox
        var md = forge.md.sha256.create();
        for (var i = 0; i < 8192; i++) {
            //start() is not expensive, but allows us to start over with same object
            md.start();
            md.update(hashstr + p);
            hashstr = md.digest().data;
        }
        return hashstr;
    }

    function xor16(a, b) {
        var x = new Uint8Array(16);
        for (i = 0; i < 16; i++)
            x[i] = a.charCodeAt(i) ^ b.charCodeAt(i);
        return arrayToString(x);
    }

    function makeext(x) {
        var lenbytes = new String;
        var t = new String;
        var len = 0;
        if (typeof x == 'string') {
            len = x.length + 1;
            t = x + String.fromCharCode(0);
        } else {
            //assume an array of strings
            for (var i = 0; i < x.length; i++) {
                len += x[i].length + 1;
                t += x[i] + String.fromCharCode(0);
            }
        }

        return String.fromCharCode(len >> 8) + String.fromCharCode(len & 0xFF) + t;
    }

    function cipherblock(key, iv, block) {
        var cipher = forge.cipher.createCipher('AES-CBC', key);
        cipher.start({ iv: iv });
        cipher.update(forge.util.createBuffer(block));
        cipher.finish();
        var mod = block.length % 16;
        //console.log(mod);
        if (mod != 0)
            return cipher.output.data;
        // don't pad file that otherwise fits exactly into 16 byte blocks.
        // forge needs the extra room for encoding a padding number in the plaintext
        // aescrypt format has the padding number outside the encrypted text.
        else
            return cipher.output.data.slice(0, -16);

    }

    /* decipher some crypttext.  skipend fixes the truncation problem that prompted much of the commented out code below */

    function decipherblock(key, iv, block, skipend) {
        var decipher = forge.cipher.createDecipher('AES-CBC', key);
        decipher.start({ iv: iv });
        decipher.update(forge.util.createBuffer(block));
        //too many negatives for a normal human brain (well, at least mine)
        // skip end of file padding if skipend = true;
        if (skipend !== true) decipher.finish();
        return decipher.output.data;
    }

    /* converting a large file to a string chokes, we need to do this a bit at a time */
    /* if its big, pass a Uint8Array instead of string                                */
    var chunksize = 16 * 1024;
    function hmacblock(key, block) {
        var hmac = forge.hmac.create();
        hmac.start('sha256', key);
        if (toType(block) == 'uint8array') {
            var l = block.length;
            //console.log(l);
            for (var i = 0; i < l; i += chunksize) {
                var end = ((i + chunksize) < l) ? i + chunksize : l;
                var s = arrayToString(block.subarray(i, end));
                //console.log("updating with:"+s);
                //console.log(s.length);
                hmac.update(s);
            }
        } else {
            hmac.update(block);
        }
        return hmac.digest().data;
    }

    //same thing, but use existing hmac, and don't finish
    function hmacchunkblock(hmac, block) {
        if (toType(block) == 'uint8array') {
            var l = block.length, s;
            //console.log(l);
            for (var i = 0; i < l; i += chunksize) {
                //var end = ( (i+chunksize)< l) ? i+chunksize: l;
                //var s=arrayToString(block.subarray(i,end));
                //console.log("updating with:"+s);
                //console.log(s.length);
                s = arrayToString(block.subarray(i, i + chunksize));
                hmac.update(s);
            }
        } else {
            hmac.update(block);
        }
    }


    /* get a key and fileiv from a 96 byte credential block */
    /* cb is an Uint8Array containing the credential block and pass is used to decrypt it */

    function getkey(cb, pass) {
        var keyiv, bufi = 0, enckeyblk, hdat, hashkey, hdatcomp, keyblock, fileiv, key, i;
        keyiv = arrayToString(cb.subarray(bufi, bufi + 16));
        bufi += 16;
        enckeyblk = arrayToString(cb.subarray(bufi, bufi + 48));
        bufi += 48;
        hdat = arrayToString(cb.subarray(bufi, bufi + 32));
        bufi += 32;
        hashkey = ivpasstokey(keyiv, pass);
        hdatcomp = hmacblock(hashkey, enckeyblk);
        //console.log ("keyiv=" + forge.util.bytesToHex(keyiv));console.log ("enckeyblk=" + forge.util.bytesToHex(enckeyblk));console.log ("hdat=" + forge.util.bytesToHex(hdat));console.log ("hashkey=" + forge.util.bytesToHex(hashkey));console.log("hdatcomp=" + forge.util.bytesToHex(hdatcomp));
        if (hdat != hdatcomp) {
            //return error
            //console.log("hmac does not match. Bad password or file corruption");
            return { key: "", fileiv: "", error: "hmac does not match. Bad password or file corruption" };
        }
        i = 0;
        keyblock = decipherblock(hashkey, keyiv, enckeyblk, true);
        if (keyblock.length != 48) {
            console.log("This shouldn't happen anymore. Please report this.");
        }
        fileiv = keyblock.slice(0, 16);
        key = keyblock.slice(16, 48);
        //console.log("keyblock.length="+keyblock.length);console.log ("key=" + forge.util.bytesToHex(key));console.log ("fileiv=" + forge.util.bytesToHex(fileiv));
        return { key: key, fileiv: fileiv, error: "" };
    }


    /*  make the 96 byte credential block ( keyiv, encrypted fileiv+key, hmac (fileiv+key) )   */
    /*  pass required, will generate key and fileiv if not provided                        */
    function newcredentialblock(pass, key, fileiv) {
        var keyiv, hashkey, keyblock, enckeyblk, tblock;
        var buffer = new Uint8Array(96);
        var d = new Date();
        forge.random.collectInt(d.getTime(), 32);

        //encrypt the iv-key combination (those used to encrypt file data)
        // and chop off the padding

        keyiv = forge.random.getBytesSync(16);
        hashkey = ivpasstokey(keyiv, pass);
        if (fileiv === undefined) fileiv = forge.random.getBytesSync(16);
        if (key === undefined) key = forge.random.getBytesSync(32);
        keyblock = fileiv + key;

        enckeyblk = cipherblock(hashkey, keyiv, keyblock).slice(0, 48);

        //this appears to be no longer a problem when using decipherblock(,,,true)
        //i.e. dont finish(), and skip padding removal which we don't have
        tblock = decipherblock(hashkey, keyiv, enckeyblk, true);
        if (tblock != keyblock) {
            //console.log("failed to find keys and ivs that forge liked...");
            //console.log("keyblock=" + forge.util.bytesToHex(keyblock));
            return "";
        }

        //console.log("keyiv="+forge.util.bytesToHex(keyiv));console.log("hashkey=" + forge.util.bytesToHex(hashkey));console.log("keyblock=" + forge.util.bytesToHex(keyblock));console.log("fileiv=" + forge.util.bytesToHex(fileiv));console.log("key=" + forge.util.bytesToHex(key));console.log("aes-cbc enckeyblock  ="+forge.util.bytesToHex(enckeyblk));console.log("encrypted iv+key length=" + enckeyblk.length);

        // 16 + 48 + 32 bytes = 96 for entire record.
        copyToArray((keyiv + enckeyblk + hmacblock(hashkey, enckeyblk)), buffer, 0)
        return { buffer: buffer, key: key, fileiv: fileiv };
    }


    /*  get the key from main keyblock or in credential blocks      *
     *  takes a Unit8Array                                          *
     *  if inextcbonly==true, we will only look for the pass in the    *
     *  extended cb block                                           *
     *  if offset is set, we start looking for extensions at that   *
     *  location instead of 5 bytes in                              */

    var getanykey = function (file, pass, inextcbonly, offset, deletekey) {
        var file, bufi, error, credext, credsize, newblock,
            key, encdata, data, i = 0, cb;

        //console.log("file="+ forge.util.bytesToHex(arrayToString(file)));
        //find our extension, skip past rest. Assume from start of file, but take offset if provided
        bufi = (offset === undefined) ? 5 : offset;

        while (bufi < file.length && (file[bufi] != 0 || file[bufi + 1] != 0)) {
            var sig, size = (file[bufi] << 8) + file[bufi + 1];
            if (size > 17) {
                sig = arrayToString(file.subarray(bufi + 2, bufi + 17));
                if (sig == "enckeyblk v 0.1") {
                    credext = bufi + 18; //2 size bytes plus ("enckeyblk v 0.1").length + 1 (0x00 at end)
                    credsize = size - 16;
                    //no need to go further, and we might not have a 0x0000 at the end anyway
                    if (inextcbonly) break;
                }
            }
            bufi += size + 2;
            if (bufi > file.length) {
                //return error
                //console.log("error finding end of extensions");
                return { key: "", fileiv: "", error: "error finding end of extensions" };
            }
        }
        // if true skip and only look in extended credential block for key.  Skip checking of main block for this password
        if (inextcbonly !== true) {
            bufi += 2;
            //get keyiv, encrypted key and file iv and hmac of encrypted key and file iv (credential block)
            cb = file.subarray(bufi, bufi + 96);
            bufi += 96;
            //console.log("looking in main block");
            key = getkey(cb, pass);
            if (key.error == "")
                return { key: key.key, fileiv: key.fileiv, error: "", masterkey: true };

        }
        var isarray = false;
        var indexarray;
        if (credext !== undefined) {
            // find non empty blocks and check for key
            // also check for request to delete key
            // if deletekey is an array, it should be an array of keyslot positions to delete
            // otherwise if ===true, it should be deleted if pass matches
            var j = 0;
            if (deletekey && typeof deletekey == 'array') {
                isarray = true;
                indexarray = [];
            }
            for (var i = 0; i < credsize; i += 96) {
                var start = i + credext;
                if (!isblank(file, start, 96)) {
                    cb = file.subarray(start, start + 96);
                    //console.log("cb="+forge.util.bytesToHex(arrayToString(cb)));
                    // if we are deleting keys at certain positions
                    if (isarray) {
                        for (var k = 0; k < deletekey.length; k++) {
                            if (deletekey[k] == j) {
                                copyToArray(new Uint8Array(96), file, start);
                                indexarray.push(j);
                                break;
                            }
                        }
                        //dont check for key.  if using array and inextcbonly===true, password can be blank
                        continue;
                    }
                    //console.log("checking keyslot "+j);
                    key = getkey(cb, pass);
                    if (key.error == "") {
                        if (deletekey === true) {
                            copyToArray(new Uint8Array(96), file, start);
                        }
                        return { key: key.key, fileiv: key.fileiv, error: "", index: j, masterkey: false };
                    }
                }
                //else console.log("empty keyslot: "+j);
                j++;
            }
        }
        if (isarray)
            return { key: "", fileiv: '', error: '', index: indexarray };
        else
            return { key: "", fileiv: '', error: "Key not found using this password" };
    }

    // an array of uint8arrays, with functions to add more and extract bytes
    // argument file and argument input in put(input) must be uint8arrays
    // no checking or error messages.
    function newbytebuf(file) {
        var buffer = [];

        if (file !== undefined) {
            file = toU8(file);

            if (toType(file) == 'uint8array') buffer = [file];

        }

        function getarrayslength(arrays) {
            var len = 0;
            for (var i = 0; i < arrays.length; i++)
                len += arrays[i].length;
            return len;
        }

        function joinarray(arrays) {
            var len = getarrayslength(arrays), ret = new Uint8Array(len);

            if (len == 0) return ret;

            len = 0;
            for (var i = 0; i < arrays.length; i++) {
                ret.set(arrays[i], len);
                len += arrays[i].length;
            }

            return ret;
        }


        return {
            // read from this buffer (amount gotten with .get() )
            read: 0,
            // written to this buffer (amount pushed with put() )
            written: getarrayslength(buffer),
            eof: false,
            buffers: buffer,
            length: 0,
            done: function () { this.eof = true; return this; },
            // only use uint8arrays for input
            put: function (input) {
                if (this.eof) {
                    //don't accept more data after eof==true
                    //console.log("already done, can't take more data");
                    this.error = "already done, can't take more data";
                    return this;
                }

                input = toU8(input);

                if (input !== undefined) {
                    this.written += input.length;
                    this.length = this.written - this.read;
                    this.buffers.push(input);
                }
                else {
                    this.error = "invalid input data in put()";
                    //console.log("invalid input data in put()");
                }
                return this;
            },
            getlength: function () {
                this.length = getarrayslength(this.buffers);
                return this.length;
            },
            // optimized if data is still in underlying arraybuffer, but we won't go crazy.  If
            // the unget data covers more than one buffer, then probably not worth it.
            // if data is an int, we are putting back data that we just got, in order with no gaps.
            // However, if that isn't possible, x should be the actual data so we have a fallback.
            // if data is an uint8array, we just unshift the new data
            unget: function (data, x) {
                if ((typeof data == 'string' || typeof data == 'number') &&
                    Math.round(data) == data) {
                    if (data <= this.slice && this.buffers.length) {
                        this.slice -= data.length;
                        //reslice the first buffer
                        var wholebuf = new Uint8Array(this.buffers[0].buffer);
                        this.buffers[0] = wholebuf.subarray(this.slice);
                        this.read -= data;
                        this.length = this.written - this.read;
                        return this;
                    } else {
                        //overlap, we'll unshift the data instead
                        data = x;
                    }
                }
                data = toU8(data);
                this.read -= data.length;
                this.buffers.unshift(data);
                this.length = this.written - this.read;
                return this;
            },
            // size=-1:  get all data as one array
            // size>0:   shift size data from buffer.  if buffer smaller than size, return undefined
            // size==undefined:  get a convenient amount of data out of the buffer;  if no data left, return undefined
            get: function (size) {
                var filebuf = this.buffers;
                if (!filebuf || !filebuf.length) return;
                // get the first block of data if undefined, or if that was the size requested
                if (size === undefined || size == filebuf[0].length) {
                    this.slice = 0;
                    this.read += size;
                    this.length = this.written - this.read;
                    return (filebuf.shift());
                }
                //return everything if -1
                //if no data in buffer, return undefined;
                if (size == -1 || size == 'all') {
                    var ret = joinarray(this.buffers);
                    this.buffers = [];
                    this.slice = 0;
                    this.read += ret.length;
                    this.length = this.written - this.read;
                    return ret;
                }

                var endbuf = 0, tail;
                var i = 0, len = 0, ret, jarray = [];

                // is there enough data in the buffer for this request
                for (i = 0; i < filebuf.length; i++) {
                    //tail is how much more we need from the next array
                    tail = size - len;
                    len += filebuf[i].length;
                    endbuf = i;
                    if (len >= size) break;
                }
                if (len < size)
                    //return undefined, just like shift above
                    return;

                if (endbuf == 0) {
                    // the easy case
                    ret = filebuf[0].subarray(0, size);
                    filebuf[0] = filebuf[0].subarray(size);
                    this.slice += size;
                    this.read += size;
                    this.length = this.written - this.read;
                    return ret;
                }

                for (i = 0; i < endbuf; i++)
                    jarray.push(filebuf.shift());

                jarray.push(filebuf[0].subarray(0, tail));

                filebuf[0] = filebuf[0].subarray(tail);
                this.slice = tail;
                ret = joinarray(jarray);
                this.read += ret.length;
                this.length = this.written - this.read;
                return ret;
            },

            // Just like get, but don't advance or update read
            // size=-1:  get all data as one array
            // size>0:   shift size data from buffer.  if buffer smaller than size, return undefined
            // size==undefined:  get a convenient amount of data out of the buffer;  if no data left, return undefined
            preview: function (size) {
                var filebuf = this.buffers;
                this.length = this.written - this.read;
                if (!filebuf || !filebuf.length) return;
                // get the first block of data if undefined, or if that was the size requested
                if (size === undefined || size == filebuf[0].length) {
                    this.bufslice = 0;
                    return (filebuf[0]);
                }
                //return everything if -1
                //if no data in buffer, return undefined;
                if (size == -1)
                    return joinarray(this.buffers);

                var endbuf = 0, tail;
                var i = 0, len = 0, ret, jarray = [];

                // is there enough data in the buffer for this request
                for (i = 0; i < filebuf.length; i++) {
                    //tail is how much more we need from the last array
                    //from which we will grab data
                    tail = size - len;
                    len += filebuf[i].length;
                    endbuf = i;
                    if (len >= size) break;
                }
                if (len < size)
                    //return undefined, just like shift above
                    return;

                if (endbuf == 0)
                    return filebuf[0].subarray(0, size);

                for (i = 0; i < endbuf; i++)
                    jarray.push(filebuf[i]);

                jarray.push(filebuf[i].subarray(0, tail));

                return joinarray(jarray);
            }
        }
    }

    /*  parsefile (file)
        takes an arraybuffer or uint8array of encrypted file and returns position of items in head
        and start of the body
        also checks format of file and returns errors;
    */

    var parsefile = function (file) {
        var bufi, credblock, credext, credextsize, head, body;

        //make sure we have a uint8array
        file = toU8(file);

        if (file === undefined)
            return { data: file, error: "bad input" };

        //check first 4 bytes
        if (!(file[0] == 0x41 && file[1] == 0x45 && file[2] == 0x53)) {
            //return error
            //console.log("bad magic");
            return { data: file, error: "bad magic" }
        }

        if (file[3] != 2) {
            //return error
            //console.log("wrong file version, only supports v2");
            return { data: file, error: "wrong file version, only supports v2" }
        }

        //find our extension, skip past rest
        bufi = 5;
        while (file[bufi] != 0 || file[bufi + 1] != 0) {
            var sig, size = (file[bufi] << 8) + file[bufi + 1];
            if (size > 17) {
                sig = arrayToString(file.subarray(bufi + 2, bufi + 17));
                if (sig == "enckeyblk v 0.1") {
                    credext = bufi + 18;
                    credextsize = size - 16;
                }
                bufi += size + 2;
            }
            if (bufi > file.length) {
                //return error
                //console.log("error finding end of extensions");
                return { data: file, error: "error finding end of extensions" };
            }
        }

        bufi += 2;
        credblock = bufi;
        return { data: file, credblock: credblock, credext: credext, credextsize: credextsize, datastart: credblock + 96, error: '' };
    }
    /** Delete passwords from the file, Not part of the aescrypt 02 format standard */

    /**
     * Delete passwords from aescrypt.js extended aescrypt 02 formatted file.
     *
     * Behavior differs from other functions.  If error, still returns the encoded file back unaltered.
     *
     * @param encfile the bytes to encrypt (either encoded as String, one byte per
     *          character, or as an ArrayBuffer or a Uint8Array).
     *
     * @param pass password String that was used for encryption 
     *
     * @param delblockarray array of ints between 0-15 specifying password-encrypted key slots to delete
     *                  or array of strings containing passwords of passwords-encrypted key to delete.
     *
     * @param requirepass whether to use password to confirm ownership of file
     *	              If set to false, blocks will be erased without confirming that pass will decrypt file
     */

    var delpass = function (encfile, pass, delblockarray, requirepass) {
        var file, error, newblock, emptyblock,
            key = "", encdata, data, i = 0, index = [], fileinfo
        var blankarray = new Uint8Array(96);


        //sanity check
        if (toType(delblockarray) == 'array') {
            var isnum = false;
            var isstring = false;
            for (var i = 0; i < delblockarray.length; i++) {
                var x = delblockarray[i];
                if (Math.round(x) == x) {
                    if (x > -1 && x < 682)
                        isnum = true;
                    //in case someone has a password of all digits (baaaaaad), lets hope the number is less than 683
                    else
                        isstring = true;
                }
                //we'll skip empty strings below
                else if (x != '')
                    isstring = true;
            }
            // we will only handle an array of all strings or all numbers
            if ((isnum && isstring) || (!isnum && !isstring))
                return { data: file, error: "delblockarray must be an array of all numbers between 0 and 682 inclusive, or an array of all password strings" }
        } else {
            return { data: file, error: "delblockarray is not an array" };
        }

        //{data:file, credblock: credblock, credext: credext, credextsize: credextsize, datastart: credblock+96, error: ''}
        //end of extensions tag (0x0000) is at credblock-2;
        //begin of extended credblock extension, including size bytes is at credext-18;

        fileinfo = parsefile(encfile);
        if (fileinfo.error != '') return fileinfo;

        file = fileinfo.data;
        if (file === undefined)
            return { data: file, error: "bad input" };

        if (fileinfo.credext === undefined) {
            //Nothing to do here
            return { data: file, error: "" };
        }

        // default is to require password
        if (requirepass !== false) {
            key = getanykey(file, pass, false, fileinfo.credext - 18);
            if (key.error != "")
                return { data: file, error: key.error };
        }

        if (isstring) {
            //find blocks matching passwords and delete it;
            var x = [];
            for (var i = 0; i < delblockarray.length; i++) {
                var key = getanykey(file, delblockarray[i], true, fileinfo.credext - 18, true);//second true means delete password
                if (key.error == '') {
                    x.push(key.index);
                }
            }
            return { data: file, error: "", index: x };
        }

        // doesn't actually check for password, only deletes.
        var key = getanykey(file, '', true, fileinfo.credext - 18, delblockarray);

        return { data: file, error: "", index: key.index };
    }



    /** Add another password to the file, Not part of the aescrypt 02 format standard */

    /**
     * Add Password to aescrypt.js extended aescrypt 02 formatted file
     *
     * Behavior differs from aes[en|de]crypt.  On error, return unaltered encrypted file
     *
     * @param encfile the bytes to encrypt (either encoded as String, one byte per
     *          character, or as an ArrayBuffer or a Uint8Array).
     *
     * @param pass password String that was used for encryption 
     *
     * @param newpass password String to add to this file. 
     */

    var addpass = function (encfile, pass, newpass) {
        var file, error, newblock, emptyblock, fileinfo,
            key, i = 0, j = 0, index;

        fileinfo = parsefile(encfile);
        if (fileinfo.error != '') return fileinfo;

        //{data:file, credblock: credblock, credext: credext, credextsize: credextsize, datastart: credblock+96, error: ''}
        //end of extensions tag (0x0000) is at credblock-2;
        //begin of extended credblock extension, including size bytes is at credext-18;

        file = fileinfo.data;

        // get a (the) key using this password.  Since we know the start of the extended credential extension, skip to that position
        key = getanykey(file, pass, false, fileinfo.credext - 18);
        if (key.error != "")
            return { data: file, error: key.error };

        newblock = newcredentialblock(newpass, key.key, key.fileiv);
        if (newblock == "") return { data: file, error: "unable to make new password entry for file" };

        if (fileinfo.credext === undefined) {
            //we have to write a new file with room for extended credential block with 16 key slots (18 + (16*96))==1554
            var endofext = fileinfo.credblock - 2;
            var newfile = new Uint8Array(file.length + 1554);
            // copy all of head up to but not including end of extension tag (0x0000)
            copyToArray(file, newfile, 0, endofext);
            //create a new credential block using newpass
            //create entry for extended credential extension
            copyToArray((String.fromCharCode(6) + String.fromCharCode(16) + "enckeyblk v 0.1" + String.fromCharCode(0)),
                newfile, endofext);
            //copy in the new credential block
            copyToArray(newblock.buffer, newfile, endofext + 18);
            //copy rest of data from original file starting with the end of extensions tag 0x0000
            copyToArray(file.subarray(endofext), newfile, endofext + 1554);
            return { data: newfile, index: 0, error: "" };
        }


        //find first empty block
        j = 0;
        for (var i = 0; i < fileinfo.credextsize; i += 96) {
            var start = i + fileinfo.credext;
            if (isblank(file, start, 96)) {
                emptyblock = start;
                index = j;
                break;
            }
            j++;
        }
        // TODO: extend it again if full.
        if (emptyblock === undefined)
            return { data: file, error: "error: all keyslots are in use" };

        copyToArray(newblock.buffer, file, emptyblock);
        return { data: file, index: index, error: "" };
    }

    /** Decrypt data in the aescrypt 02 format (ver 1 and 0 not supported) */

    /**
     * Decrypt encfile using password where encfile is in aescrypt 02 format
     * Return an ArrayBuffer of the plaintext file or a binary string
     * 
     *
     * @param encfile the bytes to encrypt (either encoded as String, one byte per
     *          character, or as an ArrayBuffer or Typed Array).
     *
     * @param pass password String that was used for encryption 
     *
     * @param returnstring boolean where if true function returns a binary string
     *
     * @param cb, callback with results
     */

    var aesdecrypt = function (encfile, pass, returnstring, cb) {
        var emptydata = new Uint8Array(0);
        //var usemod=true;

        //take a uint8array, arraybuffer or string for file
        var file = toU8(encfile);
        if (file === undefined)
            return { data: emptydata, error: "bad input" };


        /*         testing: 
        {
        //var filebuf=newbytebuf(file);		
        //or 
        var filebuf=newbytebuf(file).done();

        var key=decryptparsehead( filebuf, pass );
        var decryptor=decryptstart(key);
        // end of string is set with .done() above, so only need one pass in decryptpayload();
        //var decrypted=decryptpayload(filebuf,decryptor);
        //	while (decrypted>0) decrypted=decryptpayload(filebuf,decryptor);
        //filebuf.done();
        var decrypted=decryptpayload(filebuf,decryptor);
        var error=decryptfinish(filebuf,decryptor);
        }

        console.log("test over");
        */

        var key = decrypthead(file, pass);
        if (key.error != '') return { data: emptydata, error: key.error };

        if (crypto && crypto.subtle && typeof cb == 'function') {
            var cr = crypto.subtle;

            function checkhmac(dec) {
                cr.importKey(
                    'raw',
                    toU8(key.key),
                    { name: "HMAC", hash: { name: "SHA-256" } },
                    false,
                    ["sign", "verify"]
                ).then(function (k) {
                    cr.verify(
                        { name: "HMAC" },
                        k,
                        file.subarray(-32),
                        file.subarray(key.datastart, -33)
                    ).then(function (valid) {
                        if (valid) cb({ data: dec, error: '' });
                        else cb({ data: dec, error: "hmac does not match. Likely file corruption or tampering." })
                    }).catch(function (e) {
                        //console.log(e);
                        cb({ data: emptydata, error: e.message });
                    });;
                }).catch(function (e) {
                    //console.log(e);
                    cb({ data: emptydata, error: e.message });
                });

            }
            cr.importKey(
                'raw',
                toU8(key.key),
                { name: "AES-CBC" },
                false,
                ["encrypt", "decrypt"]
            ).then(function (k) {
                var modbyte = file[file.length - 33];
                var subfile = file.subarray(key.datastart, -33);
                //console.log(modbyte);
                if (modbyte == 0) {
                    //we can cheat our way out of the fact that the aescrypt file format fails to put padding on
                    //a size%16==0 sized file with forge api, but not with webcrypto api
                    //so just use forge instead.
                    cb(aesdecrypt(encfile, pass, returnstring));
                    return;
                }

                cr.decrypt(
                    { name: "AES-CBC", iv: toU8(key.fileiv) },
                    k,
                    subfile
                ).then(function (decrypted) {
                    decrypted = (new Uint8Array(decrypted)).subarray(0, (modbyte - 16));
                    checkhmac(decrypted);
                }).catch(function (e) {
                    //for (var x in e)
                    //	console.log(x+'='+e[x]);
                    // in case we choke somewhere.  Orignally was for above mentioned aescrypt padding problem.
                    cb(aesdecrypt(encfile, pass, returnstring)); //try with forge
                })
                    ;
            }).catch(function (e) {
                //console.log(e);
                cb({ data: emptydata, error: e.message });
            });
            return false;
        }

        var decryptor = decryptstart(key);

        var decrypted = decryptpayload(file, decryptor, key.datastart);

        if (decrypted == -1) return { data: new Uint8Array(0), error: "file corrupted (invalid length)" };

        var error = decryptfinish(file, decryptor, true);
        if (returnstring)
            return { data: decryptor.decipher.output.data, error: error };
        else {
            var a = new Uint8Array(decryptor.decipher.output.data.length);
            copyToArray(decryptor.decipher.output.data, a);
            return { data: a, error: error };
        }
    }

    // do head in one go
    function decrypthead(encfile, pass) {
        var file, fileinfo, key;

        //{data:file, credblock: credblock, credext: credext, credextsize: credextsize, datastart: credblock+96, error: ''}
        //end of extensions tag (0x0000) is at credblock-2;
        //begin of extended credblock extension, including size bytes is at credext-18;

        fileinfo = parsefile(encfile);
        if (fileinfo.error != '') return fileinfo;

        file = fileinfo.data;
        if (file === undefined)
            return { data: file, error: "bad input" };
        if (fileinfo.credext) {
            key = getanykey(file, pass, false, fileinfo.credext - 18);
        } else if (fileinfo.credblock) {
            key = getkey(file.subarray(fileinfo.credblock, fileinfo.credblock + 96), pass);
        }
        else return ({ error: "Could not parse encrypted file" });
        key.datastart = fileinfo.datastart;

        return key;

    }

    // parse head of file and get key
    // can be done in stages as more data is put into filebuf
    // cant use parsefile() if we really want to be able to handle incoming a byte at a time
    function decryptparsehead(filebuf, pass, progress) {
        if (progress === undefined) progress = { stage: 0 };
        //check first 5 bytes
        if (progress.stage == 0) {
            //need 5 bytes for stage 1;
            var file = filebuf.get(5);
            if (file == undefined) return progress;

            if (!(file[0] == 0x41 && file[1] == 0x45 && file[2] == 0x53)) {
                //return error
                //console.log("bad magic");
                return { error: "bad magic" }
            }

            if (file[3] != 2) {
                //return error
                //console.log("wrong file version, only supports v2");
                return { error: "wrong file version, only supports v2" }
            }
            progress.stage = 1;
        }
        if (progress.stage == 1) {
            file = filebuf.preview(2);
            if (file === undefined) return progress;
            while (file[0] != 0 || file[1] != 0) {
                var sig = '';
                var extsize = (file[0] << 8) + file[1] + 2;
                var lengthbytes = file;
                file = filebuf.get(extsize);
                if (file === undefined) return progress;
                // look for extended credential block
                if (file.length > 17) {
                    sig = arrayToString(file.subarray(2, 17));
                    if (sig == "enckeyblk v 0.1") {
                        var k = getanykey(file, pass, true, 0);
                        if (k.error == "") progress.key = k;
                    }
                }
                file = filebuf.preview(2);
                if (file === undefined) return progress;
            }
            file = filebuf.get(2); //skip past the final 0x0000
            progress.stage = 2;
        }
        if (progress.stage == 2) {
            // this is our main credential block containing 
            // keyiv, encrypted key and file iv and hmac of ( encrypted key + file iv)
            file = filebuf.get(96);
            if (file === undefined) return progress;
            if (progress.key) {
                progress.key.stage = 3;
                return progress.key
            } else {
                var key = getkey(file, pass);
                key.stage = 3;
                return key;
            }
            //this is the end of the header section
            //encrypted data is next
        }
    }


    // set up decipher, hmac and an object to hold them an output array
    function decryptstart(key) {
        var decipher = forge.cipher.createDecipher('AES-CBC', key.key);
        var hmac = forge.hmac.create();
        decipher.start({ iv: key.fileiv });
        hmac.start('sha256', key.key);
        return { decipher: decipher, hmac: hmac, data: newbytebuf() };
    }

    // decrypt 64 bytes at a time
    // either the buffer will need to contain the whole file, or we will
    // probably need to feed buffer 128 bytes  at a time until the end of file, or it will all break down
    // if position is defined, we assume file is a uint8array and data starts at pos
    function decryptpayload(filebuf, decryptor, pos) {

        var block;
        var len = filebuf.length;
        // 49 bytes is the minimum payload size (16 bytes encrypted data + 1 mod byte + 32 byte hmac)
        // if we are at the end of file, just encrypt what we have left.
        // if filebuf is an uint8array, pos will/should be defined
        if (filebuf.eof || pos !== undefined) {
            //console.log("got eof, doing rest of file, len="+len);

            //this should only be 33 or more.
            if (len < 33) return -1;
            if (len == 33) return 0;
            //get all but the last 33 bytes
            len -= 33;
            if (pos !== undefined)
                block = filebuf.subarray(pos, -33);
            else
                block = filebuf.get(len);
            //console.log("starting decrypt");
            decryptor.decipher.update(forge.util.createBuffer(block));
            //decryptor.hmac.update(arrayToString(block));
            //console.log("starting hmac calc");
            hmacchunkblock(decryptor.hmac, block);
            //console.log("done with decryption");
            return (len);

            // if no end of file, then leave at least 33 bytes after this round
        } else if (len > 97) {
            //console.log("no eof, leaving at least 33 in buf");
            len = len - 33;
            len = len - len % 64
            //console.log("decrypting "+len+" bytes")			
            block = filebuf.get(len);
            //now minimum in buffer is 33
            decryptor.decipher.update(forge.util.createBuffer(block));
            //decryptor.hmac.update(arrayToString(block));
            hmacchunkblock(decryptor.hmac, block);
            return (len);
        }
        return 0;
    }

    // if pos == true, filebuf is uint8array
    function decryptfinish(filebuf, decryptor, pos) {
        var hdat, hdatcomp, modbyte;

        if (pos !== true) {
            modbyte = filebuf.get(1);
            if (modbyte === undefined) return "file corrupted (no modbyte)";
            modbyte = modbyte[0];
            hdat = arrayToString(filebuf.get(-1));
        }
        else {
            pos = filebuf.length - 33;
            modbyte = filebuf[pos];
            hdat = arrayToString(filebuf.subarray(pos + 1));
        }

        if (!hdat || hdat.length != 32) return "file corrupted (invalid hmac block)";

        hdatcomp = decryptor.hmac.digest().data
        if (hdat != hdatcomp) {
            return "hmac does not match. Likely file corruption or tampering.";
        }
        if (modbyte != 0)
            decryptor.decipher.output.data = decryptor.decipher.output.data.slice(
                0, (modbyte - 16)
            );
        return "";
    }




    /** Encrypt data in the aescrypt 02 format */

    /**
     * Encrypts filecontents with pass and returns an ArrayBuffer containing a file encrypted in the aescrypt format 02.
     *
     * @param filecontents the bytes to encrypt (either encoded as String, one byte per
     *	  character, or as an ArrayBuffer or Typed Array).
     *
     * @param pass password String used for encryption 
     *
     * @param returnstring boolean if true return a binary string instead of a uint8arrray
     *
     * @param slotn number of slots for extra passwords (default 16)
     *
     * @param cb callback to receive encrypted data
     */

    var aesencrypt = function (filecontents, pass, returnstring, slotn, cb) {

        var emptydata = new Uint8Array(0);

        if (crypto && crypto.subtle && typeof cb == 'function') {
            var cr = crypto.subtle;
            var sd = encryptstart(pass, slotn, true);
            console.log("WEBCRYPTO");
            function cryptofinish(enc, hdat, head, mod) {
                var output, bufi,
                    modbyte = String.fromCharCode(mod);

                output = newbytebuf();
                output.put(head);
                output.put(enc);
                output.put(modbyte);
                output.put(hdat);

                output = output.get(-1);
                //console.log(output.length);
                return { data: output, error: "" };
            }

            function makehmac(enc) {
                cr.importKey(
                    'raw',
                    toU8(sd.key),
                    { name: "HMAC", hash: { name: "SHA-256" } },
                    false,
                    ["sign", "verify"]
                ).then(function (k) {
                    //console.log("key imported for hmac");
                    var mod = filecontents.length % 16;
                    if (mod == 0) enc = enc.subarray(0, -16);
                    cr.sign(
                        { name: "HMAC" },
                        k,
                        enc
                    ).then(function (sig) {
                        //console.log("finishing file");
                        cb(cryptofinish(enc, sig, sd.head, mod));
                    })/*.catch(function(e) {
						console.log(e);
						cb({data:emptydata,error:e.message});
					});*/;
                }).catch(function (e) {
                    //for (var x in e)
                    //	console.log(x+'='+e[x]);
                    cb({ data: emptydata, error: e.message });
                });

            }

            cr.importKey(
                'raw',
                toU8(sd.key),
                { name: "AES-CBC" },
                false,
                ["encrypt", "decrypt"]
            ).then(function (k) {
                cr.encrypt(
                    { name: "AES-CBC", iv: toU8(sd.fileiv) },
                    k,
                    toU8(filecontents)
                ).then(function (encrypted) {
                    //console.log(encrypted.byteLength);
                    makehmac(new Uint8Array(encrypted));
                }).catch(function (e) {
                    //for (var x in e)
                    //	console.log(x+'='+e[x]);
                    cb(aesencrypt(filecontents, pass, returnstring, slotn)); //try with forge
                })
                    ;
            }).catch(function (e) {
                //console.log(e);
                cb({ data: emptydata, error: e.message });
            });
            return false;
        }
        // the forge version
        var startdata = encryptstart(pass, slotn);
        var mod = encryptupdate(startdata.cipher, startdata.hmac, filecontents);
        mod %= 16;
        return encryptfinish(startdata.cipher, startdata.hmac, startdata.head, mod, returnstring);
    }

    //* set up file header and return keys and iv
    function encryptstart(pass, extrakeyslots, noforge) {
        var headstart = new Uint8Array(5);
        var endext = new Uint8Array(2);//0x0000 for no more extensions
        var extensions = [];
        var bufarray = new ArrayBuffer(96);
        var bufi = 0;
        var buffer = new Uint8Array(bufarray);
        var cred = '';
        var keyiv, extlen = 0, output,
            i = 0, //blank=new String;
            blank;
        var emptydata = new ArrayBuffer(0);
        var cipher, hmac, extrapasses = [];
        //console.log(toType(pass));
        if (toType(pass) == 'array') {
            extrapasses = pass;
            pass = extrapasses.shift();
            //console.log(pass);
            //console.log(extrapasses);
        }


        // TODO: support for other than 16, and for extending a block that is too small to fit another 
        //       password (in addpass()).  Right now, a code review of other projects would be required
        //       since they might rely on file header size being constant (dunno, hence need for review).
        // if (extrakeyslots===undefined) 
        extrakeyslots = 16;
        // max size of extension is 65536
        if (extrakeyslots > 682) extrakeyslots = 682;
        copyToArray("AES", headstart, 0);
        headstart[3] = 2;

        //headstart[4]=0; //aready 0;

        // make credentials
        //this is now mostly solved and should be successful on every attempt
        var i = 0;
        while (cred == '' && i++ < 9) {
            //if(i>1) console.log("FAILED making new credential block");
            cred = newcredentialblock(pass);
        }
        if (cred == '') {
            //console.log("tried 8 time, bailing...");
            return { head: emptydata, error: "could not make a new set of credentials" };
        }

        /* **** add extensions here **** */

        extensions.push(makeext(["CREATED_BY", "aescrypt.js 0.1"]));

        //add blank 128 byte extension

        blank = new Uint8Array(130);
        blank.set([128], 1);
        extensions.push(blank);

        //add extended credential block
        //and add extra passwords, if available;
        if (extrakeyslots > 0) {
            var csize = 16 + (96 * extrakeyslots);
            var h = String.fromCharCode(csize >>> 8) + String.fromCharCode(csize & 0xFF) + "enckeyblk v 0.1" + String.fromCharCode(0);
            blank = new Uint8Array(csize + 2);
            copyToArray(h, blank);
            var len = (extrapasses.length < 16) ? extrapasses.length : 16;
            for (var i = 0; i < len; i++) {
                var newpass = extrapasses[i],
                    newblock = newcredentialblock(newpass, cred.key, cred.fileiv),
                    start = 18 + (i * 96);

                copyToArray(newblock.buffer, blank, start);
            }
            extensions.push(blank);
        }

        /*
        blank=String.fromCharCode(0)+String.fromCharCode(128);
        for (var i=0;i<128;i++)
            blank+=String.fromCharCode(0);
        extensions.push(blank);	
    	
        //add an area for 16 96-byte blocks for extra keyiv-enckeyblk-hmac combos ("credential blocks")
        blank=String.fromCharCode(06)+String.fromCharCode(16)+"enckeyblk v 0.1"+String.fromCharCode(0);
        for (var i=0;i<1536;i++)
            blank+=String.fromCharCode(0);
        extensions.push(blank);
        */


        /* **** end add extensions  **** */

        //the last extension  - 0x0000 to mark end of extensions
        extensions.push(endext);

        // get length of all extensions
        for (var i = 0; i < extensions.length; i++)
            extlen += extensions[i].length;

        output = new Uint8Array(
            headstart.length +
            extlen +
            cred.buffer.length
        );

        bufi = 0;
        bufi += copyToArray(headstart, output, bufi);
        for (var i = 0; i < extensions.length; i++)
            bufi += copyToArray(extensions[i], output, bufi);
        bufi += copyToArray(cred.buffer, output, bufi);

        if (!noforge) {
            cipher = forge.cipher.createCipher('AES-CBC', cred.key);
            cipher.start({ iv: cred.fileiv });

            hmac = forge.hmac.create();
            hmac.start('sha256', cred.key);
            return { head: output, error: "", cipher: cipher, hmac: hmac };
        }

        return { head: output, error: "", fileiv: cred.fileiv, key: cred.key };
    }

    function encryptupdate(cipher, hmac, data, newiv) {
        var encdata;
        // newiv is a misnomer since cipher.start({iv:newiv}) doesn't work here (not sure why)
        if (newiv !== false && newiv !== undefined) {
            //cipher.start({iv:newiv});
            cipher.output.data = newiv;
            cipher.update(forge.util.createBuffer(data));
            cipher.output.data = cipher.output.data.slice(16);
        }
        else
            cipher.update(forge.util.createBuffer(data));

        hmac.update(cipher.output.data);

        return (data.length);
    }

    function encryptfinish(cipher, hmac, head, mod, returnstring) {
        var output, len, bufi, hdat,
            modbyte = String.fromCharCode(mod),
            hlen = cipher.output.data.length;

        cipher.finish();
        if (mod != 0)
            len = cipher.output.data.length;

        // don't pad file that otherwise fits exactly into 16 byte blocks.
        // forge needs the extra room for encoding a padding number in the plaintext (Section 10.3 of [RFC2315], step 2)
        // aescrypt format has the padding number outside the encrypted text.
        else
            len = cipher.output.data.length - 16;

        //how much extra data left to hmac, negative number or zero
        hlen -= len;

        //update our hmac with extra data
        if (hlen < 0)
            hmac.update(cipher.output.data.slice(hlen));

        hdat = hmac.digest().data;


        if (returnstring) {
            // do not use with chunking
            return {
                data: ("").concat(arrayToString(head), cipher.output.data.slice(0, len), modbyte, hdat),
                error: ""
            }
        } else {
            output = new Uint8Array(
                head.length +
                len +
                modbyte.length +
                hdat.length
            );
            // if getChunk is used below, head will be "" and cipher.output.data
            // will have been moved off and also be "", or a tail portion of it
            bufi = 0;
            bufi += copyToArray(head, output, bufi);
            bufi += copyToArray(cipher.output.data, output, bufi, len);
            bufi += copyToArray(modbyte, output, bufi);
            bufi += copyToArray(hdat, output, bufi);
            return { data: output, error: "" };
        }
    }


    var chunkencrypt = function (pass) {
        return {
            start: function (pass) {
                var encstart = encryptstart(pass);
                this.hmac = encstart.hmac;
                this.cipher = encstart.cipher;
                this.head = arrayToString(encstart.head);
                this.newiv = false;
                this.length = 0;
                //there really should be no errors
                this.error = encstart.error;
            },
            update: function (data) {
                this.length += encryptupdate(this.cipher, this.hmac, data, this.newiv);
                this.newiv = false;
                return this;
            },
            getChunk: function (size) {
                //return size must be a multiple of size

                var ret, retsize;

                if (this.leftover) {
                    this.cipher.output.data = this.leftover + this.cipher.output.data;
                    delete this.leftover;
                }

                retsize = parseInt((this.head.length + this.cipher.output.data.length) / size) * size;
                //console.log("retsize="+retsize+ " or "+size+ ' * ' + parseInt( (this.head.length+this.cipher.output.data.length)/size ) );

                if (retsize == 0) return;

                if (retsize == this.head.length) {
                    ret = this.head;
                } else if (retsize < this.head.length) {
                    ret = this.head.slice(0, retsize);
                    this.leftover = this.head.slice(retsize);
                } else {
                    // concat head to cipher output to make desired size
                    if (this.head.length) {
                        retsize -= this.head.length;
                        ret = this.head + this.cipher.output.data.slice(0, retsize);
                    } else {
                        ret = this.cipher.output.data.slice(0, retsize);
                    }

                    this.leftover = this.cipher.output.data.slice(retsize); //just add this on next time.
                    this.newiv = this.cipher.output.data.slice(-16); //put 16 bytes back in mix for next cbc mode computation
                    this.cipher.output.data = "";
                }

                this.head = '';
                var reta = new Uint8Array(ret.length);
                copyToArray(ret, reta);
                return { data: reta, error: "" };


                /*-------------------------- old way------------------------------------------
                ret = this.head + 
                        this.cipher.output.data;
            	
                // only update if we at least as much data as requsted
                if (size && size > ret.length)
                    return;		
                    	
                var reta=new Uint8Array(ret.length);

                if( ret.length>0)
                    copyToArray(ret,reta);
                else 
                    return;
            	
                // cbc mode needs last 16 bytes to compute next 16
                // and we'll make adjustments in next update()
                if (this.cipher.output.data.length) {
                    this.newiv=this.cipher.output.data.slice(-16);
                    this.cipher.output.data="";
                }

                this.head="";
                            	
                return {data: reta, error: ""};
                ----------------------------*/
            },
            finish: function () {
                if (this.leftover) {
                    this.cipher.output.data = this.leftover + this.cipher.output.data;
                    delete this.leftover;
                }
                var f = encryptfinish(this.cipher, this.hmac, this.head, (this.length % 16));
                return f;
            },
        }
    };

    /*
    var aesdecrypt=function(encfile,pass,returnstring) {
        var emptydata=new ArrayBuffer(0);
        //var usemod=true;

        //take a uint8array, arraybuffer or string for file
        file=toU8(encfile);
        if (file===undefined)
            return {data:emptydata, error:"bad input"};
        var filebuf=newbytebuf(file).done();
        var key=decryptparsehead( filebuf, pass );
        if (key.error!='') return {data:emptydata, error: key.error};
        var decryptor=decryptstart(key);
    	
        // end of string is set with .done() above, so only need one pass in decryptpayload();
        var decrypted=decryptpayload(filebuf,decryptor);
        if (decrypted == -1) return {data:new Uint8Array(0),error:"file corrupted"};
    	
        var error=decryptfinish(filebuf,decryptor);
        if(returnstring)
            return {data:decryptor.decipher.output.data, error: error};
        else {
            var a=new Uint8Array(decryptor.decipher.output.data.length);
            copyToArray(decryptor.decipher.output.data,a);
            return {data: a, error: error};
        }
    }
*/
    //data is not required in start;
    var chunkdecrypt = function () {
        return {
            start: function (pass) {
                if (!pass || pass == "") {
                    this.error = "password missing";
                    return this;
                }
                this.pass = pass;
                this.progress = { stage: 0 };
                this.filebuf = newbytebuf();
                this.output = newbytebuf();
                this.error = "";
                this.lasterror = "";
                delete this.decryptor;
            },
            update: function (data) {
                // go no further on unrecoverable error. error message should be in this.error;
                this.newoutput = false;
                if (this.progress.stage == -1)
                    return this;

                // push our data into the buffer
                this.filebuf.put(data);
                if (this.progress.stage < 3)
                    this.progress = decryptparsehead(this.filebuf, this.pass, this.progress);

                if (this.progress.error) {
                    this.pass = '';
                    this.error = this.progress.error;
                    this.progress.stage = -1;
                    return this;
                }

                if (this.progress.stage == 3) {
                    // we should have our key in this.progress.key
                    // this stage requires no data from filebuf

                    //dont need password lying around;
                    delete this.pass;
                    this.decryptor = decryptstart(this.progress);
                    this.progress.stage = 4;
                    //dont need key anylonger
                    delete this.key;
                }
                // kinda unnecessary since stage 3 requires no data
                // but might want to put error checking into decryptstart some day.
                if (this.progress.stage == 4) {
                    // decrypt whatever is in the buffer in multiples of 64 bytes, leaving at least 33 at end
                    var decrypted = decryptpayload(this.filebuf, this.decryptor);
                    if (decrypted > 0) {
                        this.output.put(this.decryptor.decipher.output.data);
                        this.decryptor.decipher.output.data = "";
                        this.newoutput = true;
                    } else if (decrypted == -1) {
                        this.error = "file corrupted (invalid length)";
                        this.progress.stage = -1;
                    }
                }
                return this;
            },
            getChunk: function (size) {
                var ret;
                // get all of the buffer if size undefined
                if (size === undefined) size = -1;
                if (size == 0 || !this.output)
                    return;

                ret = this.output.get(size);
                // return undefined if no data				
                if (!ret || ret.length == 0) return;

                if (this.output.eof && this.output.length == 0)
                    delete this.output;

                return { data: ret, error: this.error };
            },
            finish: function () {
                // mark eof
                this.filebuf.done();
                // finish off whatever is in the buffer
                var decrypted = decryptpayload(this.filebuf, this.decryptor);
                if (decrypted > 0) {
                    //check hmac and truncate
                    this.error = decryptfinish(this.filebuf, this.decryptor);
                    //copy output
                    this.output.put(this.decryptor.decipher.output.data);
                    //empty forge buffer
                    this.decryptor.decipher.output.data = "";
                    this.newoutput = true;
                    this.output.eof = true;
                } else if (decrypted == -1) {
                    this.error = "file corrupted (invalid length)";
                } else if (decrypted == 0) {
                    delete this.output;
                }

                this.progress.stage = -1;

                delete this.filebuf;
                delete this.decryptor;
                var lastchunk = this.getChunk();
                if (lastchunk && lastchunk.data)
                    lastchunk = lastchunk.data;
                return { data: lastchunk, error: this.error };
            },
        }
    };


    return ({
        chunkEncrypt: chunkencrypt,
        chunkDecrypt: chunkdecrypt,
        encrypt: aesencrypt,
        decrypt: aesdecrypt,
        addPassword: addpass,
        delPassword: delpass,
        util: {
            copyToArray: copyToArray,
            arrayToString: arrayToString,
            toType: toType,
            newbytebuf: newbytebuf
        }
    });
})();
