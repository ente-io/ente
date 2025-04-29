import { styled } from "@mui/material";
import React from "react";

export const FilledCircleCheck: React.FC = () => {
    return (
        <Container>
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 52 52">
                <circle cx="26" cy="26" r="25" fill="green" />
                <path fill="none" d="M14.1 27.2l7.1 7.2 16.7-16.8" />
            </svg>
        </Container>
    );
};

const Container = styled("div")`
    width: 100px;
    height: 100px;
    display: flex;
    justify-content: center;
    align-items: center;
    border-radius: 50%;
    overflow: hidden;
    animation: scaleIn 0.3s ease-in-out forwards;

    @keyframes scaleIn {
        0% {
            transform: scale(0);
        }
        50% {
            transform: scale(1.1);
        }
        100% {
            transform: scale(1);
        }
    }

    svg {
        width: 100px;
        height: 100px;

        circle {
            fill: green;
        }

        path {
            transform-origin: 50% 50%;
            stroke-dasharray: 48;
            stroke-dashoffset: 48;
            animation: strokeCheck 0.3s cubic-bezier(0.65, 0, 0.45, 1) 0.6s
                forwards;
            stroke: white;
            stroke-width: 2;
            stroke-linecap: round;
            stroke-linejoin: round;
        }
    }

    @keyframes strokeCheck {
        100% {
            stroke-dashoffset: 0;
        }
    }
`;
