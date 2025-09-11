import AddPhotoAlternateOutlinedIcon from "@mui/icons-material/AddPhotoAlternateOutlined";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import ShareIcon from "@mui/icons-material/Share";
import { useIsTouchscreen } from "ente-base/components/utils/hooks";
import { t } from "i18next";
import { useState } from "react";

interface TopNavButtonsProps {
    onAddPhotos?: () => void;
    downloadAllFiles: () => void;
    enableDownload?: boolean;
}

export const TopNavButtons: React.FC<TopNavButtonsProps> = ({
    onAddPhotos,
    downloadAllFiles,
    enableDownload,
}) => {
    const [showCopiedMessage, setShowCopiedMessage] = useState(false);
    const isTouchscreen = useIsTouchscreen();

    const handleShare = () => {
        if (typeof window !== "undefined") {
            void navigator.clipboard.writeText(window.location.href);
            setShowCopiedMessage(true);
            setTimeout(() => setShowCopiedMessage(false), 2000);
        }
    };

    const handleSignUp = () => {
        if (typeof window !== "undefined") {
            window.open("https://ente.io", "_blank", "noopener,noreferrer");
        }
    };

    const buttonStyle = {
        padding: "12px",
        backgroundColor: "rgba(255, 255, 255, 0.9)",
        border: "none",
        borderRadius: "8px",
        cursor: "pointer",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        color: "#1f2937",
        transition: "background-color 0.2s",
        backdropFilter: "blur(10px)",
        boxShadow: "0 2px 8px rgba(0, 0, 0, 0.1)",
        width: "44px",
        height: "44px",
    } as const;

    const signUpButtonStyle = {
        ...buttonStyle,
        padding: "12px 16px",
        marginLeft: "12px",
        fontSize: "16px",
        fontWeight: "600",
        whiteSpace: "nowrap",
        width: "auto",
    } as const;

    const handleButtonHover = (e: React.MouseEvent<HTMLButtonElement>) => {
        e.currentTarget.style.backgroundColor = "rgba(255, 255, 255, 1)";
    };

    const handleButtonLeave = (e: React.MouseEvent<HTMLButtonElement>) => {
        e.currentTarget.style.backgroundColor = "rgba(255, 255, 255, 0.9)";
    };

    return (
        <>
            {/* Top right buttons - Fixed to viewport */}
            <div
                style={{
                    position: "fixed",
                    top: "58px",
                    right: "58px",
                    display: "flex",
                    gap: "8px",
                    zIndex: 2000,
                }}
            >
                <button
                    onClick={handleShare}
                    style={buttonStyle}
                    onMouseEnter={handleButtonHover}
                    onMouseLeave={handleButtonLeave}
                >
                    <ShareIcon style={{ fontSize: "20px" }} />
                </button>

                {onAddPhotos && (
                    <button
                        onClick={onAddPhotos}
                        style={buttonStyle}
                        onMouseEnter={handleButtonHover}
                        onMouseLeave={handleButtonLeave}
                    >
                        <AddPhotoAlternateOutlinedIcon
                            style={{ fontSize: "22px" }}
                        />
                    </button>
                )}

                {!enableDownload && (
                    <button
                        onClick={downloadAllFiles}
                        style={buttonStyle}
                        onMouseEnter={handleButtonHover}
                        onMouseLeave={handleButtonLeave}
                    >
                        <FileDownloadOutlinedIcon
                            style={{ fontSize: "23px" }}
                        />
                    </button>
                )}

                <button
                    onClick={handleSignUp}
                    style={signUpButtonStyle}
                    onMouseEnter={handleButtonHover}
                    onMouseLeave={handleButtonLeave}
                >
                    {isTouchscreen ? t("install") : t("sign_up")}
                </button>
            </div>

            {/* Copied message */}
            {showCopiedMessage && (
                <div
                    style={{
                        position: "fixed",
                        top: "118px",
                        right: "180px",
                        backgroundColor: "#22c55e",
                        color: "white",
                        padding: "8px 16px",
                        borderRadius: "8px",
                        fontSize: "14px",
                        fontWeight: "500",
                        zIndex: 2001,
                        boxShadow: "0 4px 12px rgba(0, 0, 0, 0.2)",
                        animation: "fadeInOut 2s ease-in-out forwards",
                    }}
                >
                    Copied!
                </div>
            )}
        </>
    );
};