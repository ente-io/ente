import React from 'react';

export default function SortIcon(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}>
            <path d="M0 0h24v24H0V0z" fill="none" />
            <path
                d="M3 18h6v-2H3v2zM3 6v2h18V6H3zm0 7h12v-2H3v2z"
                fill="currentColor"
            />
        </svg>
    );
}

SortIcon.defaultProps = {
    height: 24,
    width: 24,
    viewBox: '0 0 24 24',
};
