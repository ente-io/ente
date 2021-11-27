import React from 'react';

export default function DownloadIcon(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}
            fill="currentColor">
            <g>
                <rect fill="none" height="24" width="24" />
            </g>
            <g>
                <path d="M5,20h14v-2H5V20z M19,9h-4V3H9v6H5l7,7L19,9z" />
            </g>
        </svg>
    );
}

DownloadIcon.defaultProps = {
    height: 24,
    width: 24,
    viewBox: '0 0 24 24',
};
