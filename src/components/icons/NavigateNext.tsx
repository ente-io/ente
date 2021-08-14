import React from 'react';

export default function NavigateNext(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height="40"
            viewBox="0 0 24 24"
            width="24px"
            fill="currentColor"
            {...props}>
            <path d="M0 0h24v24H0z" fill="none" />
            <path d="M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z" />
        </svg>
    );
}

NavigateNext.defaultProps = {
    height: 24,
    width: 24,
    viewBox: '0 0 24 24',
};
