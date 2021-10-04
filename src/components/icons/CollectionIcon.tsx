import React from 'react';

export default function CollectionIcon(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}>
            <path d="M6.083 4c1.38 1.612 2.578 3 4.917 3h11v13h-20v-16h4.083zm.917-2h-7v20h24v-17h-13c-1.629 0-2.305-1.058-4-3z" />
        </svg>
    );
}

CollectionIcon.defaultProps = {
    height: 20,
    width: 20,
    viewBox: '0 0 24 24',
};
