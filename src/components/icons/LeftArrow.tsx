import React from 'react';

export default function LeftArrow(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            width={props.width}
            height={props.height}
            viewBox={props.viewBox}
            fill="currentColor"
            className="bi bi-arrow-left">
            <path
                fillRule="evenodd"
                d="M15 8a.5.5 0 0 0-.5-.5H2.707l3.147-3.146a.5.5 0 1 0-.708-.708l-4 4a.5.5 0 0 0 0 .708l4 4a.5.5 0 0 0 .708-.708L2.707 8.5H14.5A.5.5 0 0 0 15 8z"
            />
        </svg>
    );
}

LeftArrow.defaultProps = {
    height: 32,
    width: 32,
    viewBox: '0 0 16 16',
};
