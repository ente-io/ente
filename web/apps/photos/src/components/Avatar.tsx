// TODO: Audit this file
/* eslint-disable react-hooks/exhaustive-deps */
import { styled } from "@mui/material";
import type { LocalUser } from "ente-accounts/services/user";
import log from "ente-base/log";
import { type EnteFile } from "ente-media/file";
import {
    avatarBackgroundColor,
    avatarBackgroundColorPublicCollectedFile,
    avatarTextColor,
} from "ente-new/photos/services/avatar";
import React, { useLayoutEffect, useState } from "react";

interface AvatarProps {
    user?: LocalUser;
    file?: EnteFile;
    email?: string;
    opacity?: number;
    emailByUserID?: Map<number, string>;
}

const AvatarBase = styled("div")<{
    colorCode: string;
    size: number;
    opacity: number | undefined;
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

const Avatar: React.FC<AvatarProps> = ({
    user,
    file,
    email,
    opacity,
    emailByUserID,
}) => {
    const [colorCode, setColorCode] = useState("");
    const [userLetter, setUserLetter] = useState<string | undefined>("");

    useLayoutEffect(() => {
        try {
            if (!file) {
                return;
            }
            if (file.ownerID !== user?.id) {
                // getting email from in-memory id-email map
                const email = emailByUserID?.get(file.ownerID);
                if (!email) {
                    log.error("email not found in userIDToEmailMap");
                    return;
                }
                setUserLetter(email[0]?.toUpperCase());
                setColorCode(avatarBackgroundColor(file.ownerID));
            } else if (file.ownerID === user.id) {
                const uploaderName = file.pubMagicMetadata?.data.uploaderName;
                if (!uploaderName) {
                    log.error(
                        "uploaderName not found in file.pubMagicMetadata.data",
                    );
                    return;
                }
                setUserLetter(uploaderName[0]?.toUpperCase());
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

            if (user?.email === email) {
                setUserLetter(email[0]?.toUpperCase());
                setColorCode(avatarBackgroundColorPublicCollectedFile);
                return;
            }

            const id = Array.from(emailByUserID?.keys() ?? []).find(
                (key) => emailByUserID?.get(key) === email,
            );
            if (!id) {
                log.error(`ID not found for email: ${email}`);
                return;
            }
            setUserLetter(email[0]?.toUpperCase());
            setColorCode(avatarBackgroundColor(id));
        } catch (e) {
            log.error("AvatarIcon.tsx - useLayoutEffect email failed", e);
        }
    }, [user, email, emailByUserID]);

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
