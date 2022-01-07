import React, { useState, useEffect } from 'react';
import styled from 'styled-components';
import { imageBitmapToBlob } from 'utils/image';
import { getBlobFromCache } from 'utils/storage/cache';

export const Image = styled.img``;

export const FaceCropsRow = styled.div`
    & > img {
        width: 256px;
        height: 256px;
    }
`;

export const FaceImagesRow = styled.div`
    & > img {
        width: 112px;
        height: 112px;
    }
`;

export function ImageCacheView(props: { url: string; cacheName: string }) {
    const [imageBlob, setImageBlob] = useState<Blob>();

    useEffect(() => {
        let didCancel = false;

        async function loadImage() {
            let blob: Blob;
            if (!props.url || !props.cacheName) {
                blob = undefined;
            } else {
                blob = await getBlobFromCache(props.cacheName, props.url);
            }

            !didCancel && setImageBlob(blob);
        }

        loadImage();
        return () => {
            didCancel = true;
        };
    }, [props.url, props.cacheName]);

    return (
        <>
            <ImageBlobView blob={imageBlob}></ImageBlobView>
        </>
    );
}

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
        try {
            setImgUrl(props.blob && URL.createObjectURL(props.blob));
        } catch (e) {
            console.error(
                'ImageBlobView: can not create object url for blob: ',
                props.blob,
                e
            );
        }
    }, [props.blob]);

    return (
        <>
            <Image src={imgUrl}></Image>
        </>
    );
}
