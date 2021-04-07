import React from 'react';

function UploadButton({ openFileUploader }) {
    return (
        <div
            onClick={openFileUploader}
            style={{
                position: 'absolute',
                right: '30px',
                top: '20px',
                zIndex: 100,
                cursor: 'pointer',
            }}
        >
            <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="green"
                width="32px"
                height="32px"
            >
                <path fill="none" d="M0 0h24v24H0z" />
                <path
                    fill="#2dc262"
                    d="M20 6h-8l-2-2H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2zm0 12H4V8h16v10zM8 13.01l1.41 1.41L11 12.84V17h2v-4.16l1.59 1.59L16 13.01 12.01 9 8 13.01z"
                />
            </svg>
        </div>
    );
}

export default UploadButton;
