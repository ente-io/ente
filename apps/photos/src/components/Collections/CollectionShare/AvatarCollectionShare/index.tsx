import React, { useState, useContext, useLayoutEffect } from 'react';
import { GalleryContext } from 'pages/gallery';
import { styled } from '@mui/material';
import { useTheme } from '@mui/material/styles';
import { logError } from 'utils/sentry';

interface AvatarProps {
    email: string;
}

const AvatarBaseCollectionShare = styled('div')<{
    colorCode: string;
    size: number;
}>`
    width: ${({ size }) => `${size}px`};
    height: ${({ size }) => `${size}px`};
    background-color: ${({ colorCode }) => `${colorCode}`};
    border-radius: 50%;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    font-weight: bold;
    font-size: ${({ size }) => `${Math.floor(size / 2)}px`};
`;

const AvatarCollectionShare: React.FC<AvatarProps> = ({ email }) => {
    const { userIDToEmailMap } = useContext(GalleryContext);
    const theme = useTheme();

    const [colorCode, setColorCode] = useState('');
    const [userLetter, setUserLetter] = useState('');

    useLayoutEffect(() => {
        try {
            if (!email) {
                logError(Error(), 'email not found in userIDToEmailMap');
                return;
            }
            const id = Array.from(userIDToEmailMap.keys()).find(
                (key) => userIDToEmailMap.get(key) === email
            );
            if (!id) {
                logError(Error(), `ID not found for email: ${email}`);
                return;
            }
            const colorIndex = id % theme.colors.avatarColors.length;
            const colorCode = theme.colors.avatarColors[colorIndex];
            setUserLetter(email[0].toUpperCase());
            setColorCode(colorCode);
        } catch (err) {
            logError(err, 'AvatarIcon.tsx - useLayoutEffect failed');
        }
    }, []);

    if (!colorCode || !userLetter) {
        return <></>;
    }

    return (
        <AvatarBaseCollectionShare size={18} colorCode={colorCode}>
            {userLetter}
        </AvatarBaseCollectionShare>
    );
};

export default AvatarCollectionShare;
