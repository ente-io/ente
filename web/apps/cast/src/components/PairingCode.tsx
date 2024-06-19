import { styled } from "@mui/material";
import React from "react";

const colors = [
    "#87CEFA", // Light Blue
    "#90EE90", // Light Green
    "#F08080", // Light Coral
    "#FFFFE0", // Light Yellow
    "#FFB6C1", // Light Pink
    "#E0FFFF", // Light Cyan
    "#FAFAD2", // Light Goldenrod
    "#87CEFA", // Light Sky Blue
    "#D3D3D3", // Light Gray
    "#B0C4DE", // Light Steel Blue
    "#FFA07A", // Light Salmon
    "#20B2AA", // Light Sea Green
    "#778899", // Light Slate Gray
    "#AFEEEE", // Light Turquoise
    "#7A58C1", // Light Violet
    "#FFA500", // Light Orange
    "#A0522D", // Light Brown
    "#9370DB", // Light Purple
    "#008080", // Light Teal
    "#808000", // Light Olive
];

interface PairingCodeProps {
    code: string;
}

export const PairingCode: React.FC<PairingCodeProps> = ({ code }) => {
    return (
        <PairingCode_>
            {code.split("").map((char, i) => (
                <span
                    key={i}
                    style={{
                        // Alternating background.
                        backgroundColor: i % 2 === 0 ? "#2e2e2e" : "#5e5e5e",
                        // Varying colors.
                        color: colors[i % colors.length],
                    }}
                >
                    {char}
                </span>
            ))}
        </PairingCode_>
    );
};

const PairingCode_ = styled("div")`
    border-radius: 10px;
    overflow: hidden;

    font-size: 4rem;
    font-weight: bold;
    font-family: monospace;

    line-height: 1.2;

    /*
     * -  We want them to be spans so that when the text is copy pasted, there
     *    is no extra whitespace inserted.
     *
     * -  But we also want them to have a block level padding.
     *
     * To achieve both these goals, make them inline-blocks
     */
    span {
        display: inline-block;
        padding: 0.5rem;
    }
`;
