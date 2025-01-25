import log from "@/base/log";
import { EnteFile } from "@/media/file";
import {
    avatarBackgroundColor,
    avatarBackgroundColorPublicCollectedFile,
    avatarTextColor,
} from "@/new/photos/services/avatar";
import { styled } from "@mui/material";
import { GalleryContext } from "pages/gallery";
import React, { useContext, useLayoutEffect, useState } from "react";

interface AvatarProps {
    file?: EnteFile;
    email?: string;
    opacity?: number;
}

const AvatarBase = styled("div")<{
    colorCode: string;
    size: number;
    opacity: number;
}>`
    width: ${({ size }) => `${size}px`};
    height: ${({ size }) => `${size}px`};
    background-color: ${({ colorCode, opacity }) =>
        `${colorCode}${opacity === 100 ? "" : (opacity ?? 95)}`};
    border-radius: 50%;
    display: flex;
    justify-content: center;
    align-items: center;
    color: ${avatarTextColor};
    font-weight: bold;
    font-size: ${({ size }) => `${Math.floor(size / 2)}px`};
`;

const Avatar: React.FC<AvatarProps> = ({ file, email, opacity }) => {
    const { userIDToEmailMap, user } = useContext(GalleryContext);

    const [colorCode, setColorCode] = useState("");
    const [userLetter, setUserLetter] = useState("");

    useLayoutEffect(() => {
        try {
            if (!file) {
                return;
            }
            if (file.ownerID !== user.id) {
                // getting email from in-memory id-email map
                const email = userIDToEmailMap.get(file.ownerID);
                if (!email) {
                    log.error("email not found in userIDToEmailMap");
                    return;
                }
                setUserLetter(email[0].toUpperCase());
                setColorCode(avatarBackgroundColor(file.ownerID));
            } else if (file.ownerID === user.id) {
                const uploaderName = file.pubMagicMetadata?.data.uploaderName;
                if (!uploaderName) {
                    log.error(
                        "uploaderName not found in file.pubMagicMetadata.data",
                    );
                    return;
                }
                setUserLetter(uploaderName[0].toUpperCase());
                setColorCode(avatarBackgroundColorPublicCollectedFile);
            }
        } catch (e) {
            log.error("AvatarIcon.tsx - useLayoutEffect file failed", e);
        }
    }, [file]);

    useLayoutEffect(() => {
        try {
            if (!email) {
                return;
            }
            if (user.email === email) {
                setUserLetter(email[0].toUpperCase());
                setColorCode(avatarBackgroundColorPublicCollectedFile);
                return;
            }

            const id = Array.from(userIDToEmailMap.keys()).find(
                (key) => userIDToEmailMap.get(key) === email,
            );
            if (!id) {
                log.error(`ID not found for email: ${email}`);
                return;
            }
            setUserLetter(email[0].toUpperCase());
            setColorCode(avatarBackgroundColor(id));
        } catch (e) {
            log.error("AvatarIcon.tsx - useLayoutEffect email failed", e);
        }
    }, [email]);

    if (!colorCode || !userLetter) {
        return <></>;
    }

    return (
        <AvatarBase size={18} colorCode={colorCode} opacity={opacity}>
            {userLetter}
        </AvatarBase>
    );
};

export default Avatar;
