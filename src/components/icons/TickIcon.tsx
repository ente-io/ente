import React from 'react';

export default function TickIcon(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}
            fill="currentColor">
            <path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z" />
        </svg>
    );
}

TickIcon.defaultProps = {
    height: 28,
    width: 20,
    viewBox: '0 0 24 24',
};
