import React from 'react';
import styled from 'styled-components';

const Wrapper = styled.div`
    font-size: 10px;
    position: absolute;
    padding: 2px;
    right: 5px;
    top: 5px;
`;
export default function LivePhotoIndicatorOverlay(props) {
    return (
        <Wrapper>
            <svg
                xmlns="http://www.w3.org/2000/svg"
                height={props.height}
                viewBox={props.viewBox}
                width={props.width}
                fill="currentColor">
                <path d="M0 0h24v24H0V0z" fill="none" />
                <path d="M6.76 4.84l-1.8-1.79-1.41 1.41 1.79 1.79zM1 10.5h3v2H1zM11 .55h2V3.5h-2zm8.04 2.495l1.408 1.407-1.79 1.79-1.407-1.408zm-1.8 15.115l1.79 1.8 1.41-1.41-1.8-1.79zM20 10.5h3v2h-3zm-8-5c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6-2.69-6-6-6zm0 10c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4-1.79 4-4 4zm-1 4h2v2.95h-2zm-7.45-.96l1.41 1.41 1.79-1.8-1.41-1.41z" />
            </svg>
        </Wrapper>
    );
}

LivePhotoIndicatorOverlay.defaultProps = {
    height: 20,
    width: 20,
    viewBox: '0 0 24 24',
};
