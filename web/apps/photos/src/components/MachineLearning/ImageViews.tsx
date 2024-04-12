import log from "@/next/log";
import { cached } from "@ente/shared/storage/cache";
import { getData, LS_KEYS } from "@ente/shared/storage/localStorage";
import { User } from "@ente/shared/user/types";
import { Skeleton } from "@mui/material";
import { useEffect, useState } from "react";
import machineLearningService from "services/machineLearning/machineLearningService";

interface FaceCropImageViewProps {
    url: string;
    faceID: string;
}

export const FaceCropImageView: React.FC<FaceCropImageViewProps> = ({
    url,
    faceID,
}) => {
    const [imageBlob, setImageBlob] = useState<Blob>();

    useEffect(() => {
        let didCancel = false;
        async function loadImage() {
            try {
                const user: User = getData(LS_KEYS.USER);
                let blob: Blob;
                if (!url || !user) {
                    blob = undefined;
                } else {
                    blob = await cached("face-crops", url, async () => {
                        try {
                            log.debug(
                                () =>
                                    `ImageCacheView: regenerate face crop for ${faceID}`,
                            );
                            return machineLearningService.regenerateFaceCrop(
                                user.token,
                                user.id,
                                faceID,
                            );
                        } catch (e) {
                            log.error(
                                "ImageCacheView: regenerate face crop failed",
                                e,
                            );
                        }
                    });
                }

                !didCancel && setImageBlob(blob);
            } catch (e) {
                log.error("ImageCacheView useEffect failed", e);
            }
        }
        loadImage();
        return () => {
            didCancel = true;
        };
    }, [url, faceID]);

    return <ImageBlobView blob={imageBlob}></ImageBlobView>;
};

const ImageBlobView = (props: { blob: Blob }) => {
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
};
