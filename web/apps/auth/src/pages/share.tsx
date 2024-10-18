import { EnteLogo } from "@/base/components/EnteLogo";
import { decryptMetadataJSON_New } from "@/base/crypto";
import React, { useEffect, useMemo, useState } from "react";

interface SharedCode {
    startTime: number;
    step: number;
    codes: string;
}

interface CodeDisplay {
    currentCode: string;
    nextCode: string;
    progress: number;
}

const Share: React.FC = () => {
    const [sharedCode, setSharedCode] = useState<SharedCode | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [timeStatus, setTimeStatus] = useState<number>(-10);
    const [codeDisplay, setCodeDisplay] = useState<CodeDisplay>({
        currentCode: "",
        nextCode: "",
        progress: 0,
    });

    const base64UrlToByteArray = (base64Url: string): Uint8Array => {
        const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
        return Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
    };

    const formatCode = (code: string): string =>
        code.replace(/(.{3})/g, "$1 ").trim();

    const getCodeDisplay = (
        codes: string[],
        startTime: number,
        stepDuration: number,
    ): CodeDisplay => {
        const currentTime = Date.now();
        const elapsedTime = (currentTime - startTime) / 1000;
        const index = Math.floor(elapsedTime / stepDuration);
        const progress = ((elapsedTime % stepDuration) / stepDuration) * 100;

        return {
            currentCode: formatCode(codes[index] || ""),
            nextCode: formatCode(codes[index + 1] || ""),
            progress,
        };
    };

    const getTimeStatus = (
        currentTime: number,
        startTime: number,
        codesLength: number,
        stepDuration: number,
    ): number => {
        if (currentTime < startTime) return -1;
        const totalDuration = codesLength * stepDuration * 1000;
        if (currentTime > startTime + totalDuration) return 1;
        return 0;
    };

    useEffect(() => {
        const decryptCode = async () => {
            const urlParams = new URLSearchParams(window.location.search);
            const data = urlParams.get("data");
            const header = urlParams.get("header");
            const key = window.location.hash.substring(1);

            if (!(data && header && key)) {
                setError("Invalid URL. Please check the URL.");
                return;
            }

            try {
                const decryptedCode = (await decryptMetadataJSON_New(
                    {
                        encryptedData: base64UrlToByteArray(data),
                        decryptionHeader: base64UrlToByteArray(header),
                    },
                    base64UrlToByteArray(key),
                )) as SharedCode;
                setSharedCode(decryptedCode);
            } catch (error) {
                console.error("Failed to decrypt data:", error);
                setError(
                    "Failed to get the data. Please check the URL and try again.",
                );
            }
        };
        decryptCode();
    }, []);

    useEffect(() => {
        if (!sharedCode) return;

        const updateCode = () => {
            const currentTime = Date.now();
            const codes = sharedCode.codes.split(",");
            const status = getTimeStatus(
                currentTime,
                sharedCode.startTime,
                codes.length,
                sharedCode.step,
            );
            setTimeStatus(status);

            if (status === 0) {
                setCodeDisplay(
                    getCodeDisplay(
                        codes,
                        sharedCode.startTime,
                        sharedCode.step,
                    ),
                );
            }
        };

        const interval = setInterval(updateCode, 100);
        return () => clearInterval(interval);
    }, [sharedCode]);

    const progressBarColor = useMemo(
        () => (100 - codeDisplay.progress > 40 ? "#8E2DE2" : "#FFC107"),
        [codeDisplay.progress],
    );

    const Message: React.FC<{ text: string }> = ({ text }) => (
        <p style={{ textAlign: "center", fontSize: "24px" }}>{text}</p>
    );

    return (
        <div
            style={{
                display: "flex",
                flexDirection: "column",
                justifyContent: "space-between",
                alignItems: "center",
                height: "100vh",
                backgroundColor: "#000000",
                color: "#FFFFFF",
                padding: "20px",
            }}
        >
            <EnteLogo />

            <div style={{ width: "100%", maxWidth: "300px" }}>
                {error && <p style={{ color: "red" }}>{error}</p>}
                {timeStatus === -10 && !error && (
                    <Message text="Decrypting..." />
                )}
                {timeStatus === -1 && (
                    <Message text="Your or the person who shared the code has out of sync time." />
                )}
                {timeStatus === 1 && <Message text="The code has expired." />}
                {timeStatus === 0 && (
                    <div
                        style={{
                            backgroundColor: "#1C1C1E",
                            borderRadius: "10px",
                            paddingBottom: "20px",
                            position: "relative",
                        }}
                    >
                        <div
                            style={{
                                width: "100%",
                                height: "4px",
                                backgroundColor: "#333333",
                                borderRadius: "2px",
                            }}
                        >
                            <div
                                style={{
                                    width: `${100 - codeDisplay.progress}%`,
                                    height: "100%",
                                    backgroundColor: progressBarColor,
                                    borderRadius: "2px",
                                }}
                            />
                        </div>
                        <div
                            style={{
                                fontSize: "36px",
                                fontWeight: "bold",
                                margin: "10px",
                            }}
                        >
                            {codeDisplay.currentCode}
                        </div>
                        <div
                            style={{
                                position: "absolute",
                                right: "20px",
                                bottom: "20px",
                                fontSize: "12px",
                                opacity: 0.6,
                            }}
                        >
                            <p style={{ margin: 0 }}>
                                {codeDisplay.nextCode === ""
                                    ? "Last code"
                                    : "next"}
                            </p>
                            {codeDisplay.nextCode !== "" && (
                                <p style={{ margin: 0 }}>
                                    {codeDisplay.nextCode}
                                </p>
                            )}
                        </div>
                    </div>
                )}
            </div>

            <a
                href="https://ente.io/auth"
                target="_blank"
                rel="noopener noreferrer"
            >
                <button
                    style={{
                        backgroundColor: "#8E2DE2",
                        color: "#FFFFFF",
                        border: "none",
                        borderRadius: "25px",
                        padding: "15px 30px",
                        fontSize: "16px",
                        fontWeight: "bold",
                        cursor: "pointer",
                        width: "100%",
                        maxWidth: "300px",
                        marginBottom: "42px",
                    }}
                >
                    Try Ente Auth
                </button>
            </a>
        </div>
    );
};

export default Share;
