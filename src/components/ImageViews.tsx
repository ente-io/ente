import React, { useState, useEffect } from 'react';
import styled from 'styled-components';
import { imageBitmapToBlob } from 'utils/image';

const Image = styled.img``;

export function ImageBitmapView(props: { image: ImageBitmap }) {
    const [imageBlob, setImageBlob] = useState<Blob>();

    useEffect(() => {
        let didCancel = false;

        async function loadImage() {
            const blob = props.image && (await imageBitmapToBlob(props.image));
            !didCancel && setImageBlob(blob);
        }

        loadImage();
        return () => {
            didCancel = true;
        };
    }, [props.image]);

    return (
        <>
            <ImageBlobView blob={imageBlob}></ImageBlobView>
        </>
    );
}

export function ImageBlobView(props: { blob: Blob }) {
    const [imgUrl, setImgUrl] = useState<string>();

    useEffect(() => {
        setImgUrl(props.blob && URL.createObjectURL(props.blob));
    }, [props.blob]);

    return (
        <>
            <Image src={imgUrl}></Image>
        </>
    );
}
