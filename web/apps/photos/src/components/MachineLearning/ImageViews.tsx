import { Skeleton, styled } from "@mui/material";
import { useEffect, useState } from "react";

import { addLogLine } from "@ente/shared/logging";
import { logError } from "@ente/shared/sentry";
import { cached } from "@ente/shared/storage/cacheStorage/helpers";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import { User } from "@ente/shared/user/types";
import machineLearningService from "services/machineLearning/machineLearningService";
import { imageBitmapToBlob } from "utils/image";

export const FaceCropsRow = styled("div")`
    & > img {
        width: 256px;
        height: 256px;
    }
`;

export const FaceImagesRow = styled("div")`
    & > img {
        width: 112px;
        height: 112px;
    }
`;

export function ImageCacheView(props: {
    url: string;
    cacheName: string;
    faceID: string;
}) {
    const [imageBlob, setImageBlob] = useState<Blob>();

    useEffect(() => {
        let didCancel = false;
        async function loadImage() {
            try {
                const user: User = getData(LS_KEYS.USER);
                let blob: Blob;
                if (!props.url || !props.cacheName || !user) {
                    blob = undefined;
                } else {
                    blob = await cached(
                        props.cacheName,
                        props.url,
                        async () => {
                            try {
                                addLogLine(
                                    "ImageCacheView: regenerate face crop",
                                    props.faceID,
                                );
                                return machineLearningService.regenerateFaceCrop(
                                    user.token,
                                    user.id,
                                    props.faceID,
                                );
                            } catch (e) {
                                logError(
                                    e,
                                    "ImageCacheView: regenerate face crop failed",
                                );
                            }
                        },
                    );
                }

                !didCancel && setImageBlob(blob);
            } catch (e) {
                logError(e, "ImageCacheView useEffect failed");
            }
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
                "ImageBlobView: can not create object url for blob: ",
                props.blob,
                e,
            );
        }
    }, [props.blob]);

    return imgUrl ? (
        <img src={imgUrl} />
    ) : (
        <Skeleton variant="circular" height={120} width={120} />
    );
}
