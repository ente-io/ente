import React, { useState, useContext, useLayoutEffect } from 'react';
import { EnteFile } from 'types/file';
import { User } from 'types/user';
import { GalleryContext } from 'pages/gallery';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import darkThemeColors from 'themes/colors/dark';
import { styled } from '@mui/material';

interface AvatarCircleProps {
    file: EnteFile;
}

const Avatar = styled('div')<{ colorCode: string; size: number }>`
    width: ${({ size }) => `${size}px`};
    height: ${({ size }) => `${size}px`};
    background-color: ${({ colorCode }) => `${colorCode}95`};
    border-radius: 50%;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    font-weight: bold;
    font-size: ${({ size }) => `${Math.floor(size / 2)}px`};
`;

const AvatarCircle: React.FC<AvatarCircleProps> = ({ file }) => {
    const [colorCode, setColorCode] = useState('');
    const [userLetter, setUserLetter] = useState('');
    const { idToMail } = useContext(GalleryContext);

    const user: User = getData(LS_KEYS.USER);

    useLayoutEffect(() => {
        const main = async () => {
            let email: string;
            // checking cache
            if (idToMail.has(file.ownerID)) {
                email = idToMail.get(file.ownerID);
            } else {
                email = '';
            }

            if (file.ownerID !== user.id && idToMail.has(file.ownerID)) {
                setUserLetter(email?.charAt(0)?.toUpperCase());
                const colorIndex =
                    file.ownerID % darkThemeColors.avatarColors.length;
                const colorCode = darkThemeColors.avatarColors[colorIndex];
                setColorCode(colorCode);
            } else if (
                file.ownerID === user.id &&
                file.pubMagicMetadata?.data?.uploaderName
            ) {
                const uploaderName = file.pubMagicMetadata?.data?.uploaderName;
                setUserLetter(uploaderName?.charAt(0)?.toUpperCase());
                const colorCode = '#000000';
                setColorCode(colorCode);
            }
        };
        main();
    }, []);

    return (
        <Avatar size={18} colorCode={colorCode}>
            {userLetter}
        </Avatar>
    );
};

export default AvatarCircle;
