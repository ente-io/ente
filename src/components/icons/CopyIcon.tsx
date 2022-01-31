import React from 'react';

export default function CopyIcon(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}>
            <path d="M22 6v16h-16v-16h16zm2-2h-20v20h20v-20zm-24 17v-21h21v2h-19v19h-2z" />
        </svg>
    );
}

CopyIcon.defaultProps = {
    height: 20,
    width: 20,
    viewBox: '0 0 24 24',
};
