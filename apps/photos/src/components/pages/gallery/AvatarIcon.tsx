import React from 'react';

interface AvatarCircleProps {
    email: string;
    color: string;
    size: number;
}

const AvatarCircle: React.FC<AvatarCircleProps> = ({ email, color, size }) => {
    const circleStyle = {
        width: `${size}px`,
        height: `${size}px`,
        backgroundColor: color,
        borderRadius: '50%',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        color: '#fff',
        fontWeight: 'bold',
        fontSize: `${Math.floor(size / 2)}px`,
    };

    return <div style={circleStyle}>{email}</div>;
};

export default AvatarCircle;
