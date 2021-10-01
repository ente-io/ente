import React from 'react';

export default function MoveIcon(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}>
            <path d="M0 0h24v24H0V0z" fill="none" />
            <path d="M12 4l-1.41 1.41L16.17 11H4v2h12.17l-5.58 5.59L12 20l8-8-8-8z" />
        </svg>
    );
}

MoveIcon.defaultProps = {
    height: 24,
    width: 24,
    viewBox: '0 0 24 24',
};
