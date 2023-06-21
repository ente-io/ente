import React, { useEffect, useState, useContext } from 'react';
import { EnteFile } from 'types/file';
import { User } from 'types/user';
import { GalleryContext } from 'pages/gallery';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import darkThemeColors from 'themes/colors/dark';

interface AvatarCircleProps {
    file: EnteFile;
}

const AvatarCircle: React.FC<AvatarCircleProps> = ({ file }) => {
    const [colorCode, setColorCode] = useState('');
    const [userLetter, setUserLetter] = useState('');
    const { idToMail } = useContext(GalleryContext);
    const size = 20;
    const circleStyle = {
        width: `${size}px`,
        height: `${size}px`,
        backgroundColor: `${colorCode}80`,
        borderRadius: '50%',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        color: '#fff',
        radius: '9px',

        fontWeight: 'bold',
        fontSize: `${Math.floor(size / 2)}px`,
    };
    const user: User = getData(LS_KEYS.USER);

    useEffect(() => {
        const avatarEnabledFiles = async (file: EnteFile) => {
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
        avatarEnabledFiles(file);
    }, []);

    return <div style={circleStyle}>{userLetter}</div>;
};

export default AvatarCircle;
