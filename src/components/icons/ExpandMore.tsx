import React from 'react';
export default function ExpandMore(props) {
    return (
        <div>
            <svg
                xmlns="http://www.w3.org/2000/svg"
                height={props.height}
                viewBox={props.viewBox}
                width={props.width}
                fill="#000000">
                <path d="M24 24H0V0h24v24z" fill="none" opacity=".87" />
                <path d="M16.59 8.59L12 13.17 7.41 8.59 6 10l6 6 6-6-1.41-1.41z" />
            </svg>
        </div>
    );
}

ExpandMore.defaultProps = {
    height: 24,
    width: 24,
    viewBox: '0 0 24 24',
    open: false,
};
