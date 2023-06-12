import React from 'react';

interface CircleProps {
    letter: string;
    color: string;
    size: number;
}

const Circle: React.FC<CircleProps> = ({ letter, color, size }) => {
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

    return <div style={circleStyle}>{letter}</div>;
};

export default Circle;
