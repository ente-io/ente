import React from 'react';
import styled from 'styled-components';

export default function LocationIcon(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}
        >
            <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zM7 9c0-2.76 2.24-5 5-5s5 2.24 5 5c0 2.88-2.88 7.19-5 9.88C9.92 16.21 7 11.85 7 9z"></path>
            <circle cx="12" cy="9" r="2.5"></circle>
        </svg>
    );
}

LocationIcon.defaultProps = {
    height: 20,
    width: 20,
    viewBox: '0 0 24 24',
};
