import React from 'react';

export default function Archive(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}
            fill="currentColor">
            <path d="M10 3h4v5h3l-5 5-5-5h3v-5zm8.546 0h-2.344l5.467 9h-4.669l-2.25 3h-5.5l-2.25-3h-4.666l5.46-9h-2.317l-5.477 8.986v9.014h24v-9.014l-5.454-8.986z" />
        </svg>
    );
}

Archive.defaultProps = {
    height: 28,
    width: 20,
    viewBox: '0 0 24 24',
};
