import React, { useState } from 'react';

export default function Test() {
    const [mediaUrl, setMediaUrl] = useState<string>();

    const startStream = async () => {
        const source = new MediaSource();
        const url = URL.createObjectURL(source);
        setMediaUrl(url);

        source.addEventListener('sourceopen', async () => {
            if (!source.sourceBuffers.length) {
                console.log('supported', MediaSource.isTypeSupported('video/mp4; codecs="avc1.64000d,mp4a.40.2"'));
                const sourceBuffer = source.addSourceBuffer('video/mp4; codecs="avc1.64000d,mp4a.40.2"');
                const resp = await fetch('https://nickdesaulniers.github.io/netfix/demo/frag_bunny.mp4');
                const reader = resp.body.getReader();
                new ReadableStream({
                    start() {
                        // The following function handles each data chunk
                        function push() {
                            console.log('read', source.readyState);
                            // "done" is a Boolean and value a "Uint8Array"
                            reader.read().then(({ done, value }) => {
                                // Is there more data to read?
                                if (!done) {
                                    sourceBuffer.appendBuffer(value);
                                } else {
                                    console.log('close');
                                    source.endOfStream();
                                }
                            });
                        };
    
                        sourceBuffer.addEventListener('updateend', () => {
                            push();
                        });
    
                        push();
                    }
                });
            }
        });

        source.addEventListener('sourceended', () => {
            console.log('sourceend');
        });
    }

    return (<div>
        <button onClick={startStream}>Stream Video</button>
        <div>
        {
            mediaUrl &&
            (<video width={640} height={360} controls>
                <source src={mediaUrl} />
            </video>)
        }
        </div>
    </div>)
}