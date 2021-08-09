

import React from 'react';
export default function ExpandLess(props) {
    return (
        <div >
            <svg
                xmlns="http://www.w3.org/2000/svg"
                height={props.height}
                viewBox={props.viewBox}
                width={props.width}
                fill="#000000">
                <path d="M0 0h24v24H0V0z" fill="none"/>
                <path d="M12 8l-6 6 1.41 1.41L12 10.83l4.59 4.58L18 14l-6-6z"/>
            </svg>
        </div>

    );
}

ExpandLess.defaultProps = {
    height: 24,
    width: 24,
    viewBox: '0 0 24 24',
    open: false,
};
