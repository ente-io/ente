import React from 'react';

export default function ArrowEast(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}
            {...props}>
            <rect fill="none" height="24" width="24" />
            <path d="M15,5l-1.41,1.41L18.17,11H2V13h16.17l-4.59,4.59L15,19l7-7L15,5z" />
        </svg>
    );
}

ArrowEast.defaultProps = {
    height: 24,
    width: 24,
    viewBox: '0 0 24 24',
};
