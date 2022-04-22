import React from 'react';

export default function FavoriteIcon(props) {
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height={props.height}
            viewBox={props.viewBox}
            width={props.width}>
            <path
                d="M16.6484 6.04L11.8084 5.62L9.91836 1.17C9.57836 0.36 8.41836 0.36 8.07836 1.17L6.18836 5.63L1.35836 6.04C0.478364 6.11 0.118364 7.21 0.788364 7.79L4.45836 10.97L3.35836 15.69C3.15836 16.55 4.08836 17.23 4.84836 16.77L8.99836 14.27L13.1484 16.78C13.9084 17.24 14.8384 16.56 14.6384 15.7L13.5384 10.97L17.2084 7.79C17.8784 7.21 17.5284 6.11 16.6484 6.04ZM8.99836 12.4L5.23836 14.67L6.23836 10.39L2.91836 7.51L7.29836 7.13L8.99836 3.1L10.7084 7.14L15.0884 7.52L11.7684 10.4L12.7684 14.68L8.99836 12.4Z"
                fill="white"
            />
        </svg>
    );
}

FavoriteIcon.defaultProps = {
    height: 24,
    width: 24,
    viewBox: '0 0 24 24',
};
