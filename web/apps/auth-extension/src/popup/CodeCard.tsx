/**
 * Individual code display card component.
 * Matches the Ente Auth app design.
 */
import React, { useState, useEffect, useRef } from "react";
import { prettyFormatCode } from "@shared/code";
import { getProgress } from "@shared/otp";
import type { Code } from "@shared/types";

interface CodeCardProps {
    code: Code;
    timeOffset: number;
    otp: string;
    nextOtp: string;
}

export const CodeCard: React.FC<CodeCardProps> = ({
    code,
    timeOffset,
    otp,
    nextOtp,
}) => {
    const [copied, setCopied] = useState(false);
    const [progress, setProgress] = useState(() => getProgress(code, timeOffset));
    const animationFrameRef = useRef<number | undefined>(undefined);

    // Animate progress bar smoothly using requestAnimationFrame
    useEffect(() => {
        const updateProgress = () => {
            setProgress(getProgress(code, timeOffset));
            animationFrameRef.current = requestAnimationFrame(updateProgress);
        };

        animationFrameRef.current = requestAnimationFrame(updateProgress);

        return () => {
            if (animationFrameRef.current) {
                cancelAnimationFrame(animationFrameRef.current);
            }
        };
    }, [code, timeOffset]);

    const handleCardClick = async () => {
        try {
            await navigator.clipboard.writeText(otp);
            setCopied(true);
            setTimeout(() => setCopied(false), 1500);
        } catch (error) {
            console.error("Failed to copy:", error);
        }
    };

    // Progress bar turns yellow when < 40% time remaining
    const isWarning = progress < 0.4;

    return (
        <div
            className={`code-card ${copied ? "copied" : ""}`}
            onClick={handleCardClick}
        >
            {/* Progress bar at top */}
            <div
                className={`code-progress-bar ${isWarning ? "warning" : ""}`}
                style={{ width: `${progress * 100}%` }}
            />

            {/* Pin indicator */}
            {code.codeDisplay?.pinned && (
                <>
                    <div className="pin-ribbon" />
                    <span className="pin-icon">
                        <svg viewBox="0 0 24 24" fill="currentColor" width="14" height="14">
                            <path d="M16,12V4H17V2H7V4H8V12L6,14V16H11.2V22H12.8V16H18V14L16,12Z" />
                        </svg>
                    </span>
                </>
            )}

            {/* Card content */}
            <div className="code-content">
                <div className="code-left">
                    <div className="code-issuer">{code.issuer}</div>
                    <div className="code-account">{code.account || ""}</div>
                    <div className="code-otp">
                        {copied ? "Copied!" : prettyFormatCode(otp)}
                    </div>
                </div>
                <div className="code-right">
                    <div className="code-next-label">Next</div>
                    <div className="code-next-otp">{prettyFormatCode(nextOtp)}</div>
                </div>
            </div>
        </div>
    );
};
