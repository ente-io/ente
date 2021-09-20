import React from 'react';

export default function MoveIcon(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}>
            <path d="M13.025 1l-2.847 2.828 6.176 6.176h-16.354v3.992h16.354l-6.176 6.176 2.847 2.828 10.975-11z" />
        </svg>
    );
}

MoveIcon.defaultProps = {
    height: 20,
    width: 20,
    viewBox: '0 0 24 24',
};
