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
    const [objectURL, setObjectURL] = useState<string | undefined>();

    useEffect(() => {
        let didCancel = false;

        async function loadImage() {
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

            if (didCancel) return;
            setObjectURL(URL.createObjectURL(blob));
        }

        loadImage();

        return () => {
            didCancel = true;
            if (objectURL) URL.revokeObjectURL(objectURL);
        };
    }, [url, faceID]);

    return objectURL ? (
        <img src={objectURL} />
    ) : (
        <Skeleton variant="circular" height={120} width={120} />
    );
};
