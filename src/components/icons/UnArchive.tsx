import React from 'react';

export default function UnArchive(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}
            fill="currentColor">
            <path d="M24 11.986v9.014h-24v-9.014l5.477-8.986h2.317l-5.46 9h4.666l2.25 3h5.5l2.25-3h4.669l-5.467-9h2.344l5.454 8.986zm-10-3.986h3l-5-5-5 5h3v5h4v-5zm-11.666 4" />
        </svg>
    );
}

UnArchive.defaultProps = {
    height: 28,
    width: 20,
    viewBox: '0 0 24 24',
};
