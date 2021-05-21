import React from 'react';
import styled from 'styled-components';

export default function DateIcon(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}
        >
            <path d="M19 4h-1V2h-2v2H8V2H6v2H5c-1.11 0-1.99.9-1.99 2L3 20a2 2 0 0 0 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 16H5V10h14v10zm-4.5-7a2.5 2.5 0 0 0 0 5 2.5 2.5 0 0 0 0-5z"></path>
        </svg>
    );
}

DateIcon.defaultProps = {
    height: 24,
    width: 24,
    viewBox: '0 0 24 24',
};
