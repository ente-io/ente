import { useEffect, useState } from 'react';

export default function TimerBar({ percentage }: { percentage: number }) {
    const okColor = '#75C157';
    const warningColor = '#FFC000';
    const lateColor = '#FF0000';

    const [backgroundColor, setBackgroundColor] = useState(okColor);

    useEffect(() => {
        if (percentage >= 40) {
            setBackgroundColor(okColor);
        } else if (percentage >= 20) {
            setBackgroundColor(warningColor);
        } else {
            setBackgroundColor(lateColor);
        }
    }, [percentage]);

    return (
        <div
            style={{
                width: `${percentage}%`, // Set the width based on the time left
                height: '10px', // Same as the border thickness
                backgroundColor, // The color of the moving border
                transition: 'width 1s linear', // Smooth transition for the width change
            }}
        />
    );
}
