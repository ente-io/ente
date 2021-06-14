import React from 'react';

export default function AddIcon(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}
            fill='currentColor'
        >
            <g><rect fill="none" height="24" width="24"/></g><g><g><path d="M19,13h-6v6h-2v-6H5v-2h6V5h2v6h6V13z"/></g></g>
        </svg>
    );
}

AddIcon.defaultProps = {
    height: 24,
    width: 24,
    viewBox: '0 0 24 24',
};
