import React from 'react';

export default function WarningIcon(props) {
    return (
        <div
            style={{
                color: 'red',
                display: 'inline-block',
                padding: '0 10px',
            }}>
            <svg
                xmlns="http://www.w3.org/2000/svg"
                height={props.height}
                viewBox={props.viewBox}
                width={props.width}
                fill="currentColor">
                <path d="M12 2c5.514 0 10 4.486 10 10s-4.486 10-10 10-10-4.486-10-10 4.486-10 10-10zm0-2c-6.627 0-12 5.373-12 12s5.373 12 12 12 12-5.373 12-12-5.373-12-12-12zm-1 6h2v8h-2v-8zm1 12.25c-.69 0-1.25-.56-1.25-1.25s.56-1.25 1.25-1.25 1.25.56 1.25 1.25-.56 1.25-1.25 1.25z" />
            </svg>
        </div>
    );
}

WarningIcon.defaultProps = {
    height: 24,
    width: 24,
    viewBox: '0 0 24 24',
};
