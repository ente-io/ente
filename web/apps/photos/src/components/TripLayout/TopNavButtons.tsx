import AddPhotoAlternateOutlinedIcon from "@mui/icons-material/AddPhotoAlternateOutlined";
import CheckIcon from "@mui/icons-material/Check";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import ShareIcon from "@mui/icons-material/Share";
import { Box, Button, IconButton, styled } from "@mui/material";
import { FeedIcon } from "components/Collections/CollectionHeader";
import { useIsTouchscreen } from "ente-base/components/utils/hooks";
import type { PublicAlbumsCredentials } from "ente-base/http";
import type { Collection } from "ente-media/collection";
import { Notification } from "ente-new/photos/components/Notification";
import { useJoinAlbum } from "hooks/useJoinAlbum";
import { t } from "i18next";
import { useState } from "react";
import { getSignUpOrInstallURL } from "utils/public-album";

interface TopNavButtonsProps {
    onAddPhotos?: () => void;
    downloadAllFiles: () => void;
    enableDownload?: boolean;
    onShowFeed?: () => void;
    publicCollection?: Collection;
    accessToken?: string;
    collectionKey?: string;
    credentials?: React.RefObject<PublicAlbumsCredentials | undefined>;
}

export const TopNavButtons: React.FC<TopNavButtonsProps> = ({
    onAddPhotos,
    downloadAllFiles,
    enableDownload,
    onShowFeed,
    publicCollection,
    accessToken,
    collectionKey,
    credentials,
}) => {
    const [showCopiedMessage, setShowCopiedMessage] = useState(false);
    const isTouchscreen = useIsTouchscreen();

    const enableJoin = publicCollection?.publicURLs[0]?.enableJoin;
    const { handleJoinAlbum } = useJoinAlbum({
        publicCollection,
        accessToken,
        collectionKey,
        credentials,
    });

    const handleShare = () => {
        if (typeof window !== "undefined") {
            void navigator.clipboard.writeText(window.location.href);
            setShowCopiedMessage(true);
            setTimeout(() => setShowCopiedMessage(false), 2000);
        }
    };

    const handleSignUpOrInstall = () => {
        if (typeof window !== "undefined") {
            window.open(
                getSignUpOrInstallURL(isTouchscreen),
                "_blank",
                "noopener",
            );
        }
    };

    const buttonText = enableJoin
        ? t("join_album")
        : isTouchscreen
          ? t("install")
          : t("sign_up");

    return (
        <>
            <ButtonContainer>
                <NavButton onClick={handleShare}>
                    <ShareIcon sx={{ fontSize: "20px" }} />
                </NavButton>

                {onShowFeed && (
                    <NavButton onClick={onShowFeed}>
                        <FeedIcon />
                    </NavButton>
                )}

                {onAddPhotos && (
                    <NavButton onClick={onAddPhotos}>
                        <AddPhotoAlternateOutlinedIcon
                            sx={{ fontSize: "22px" }}
                        />
                    </NavButton>
                )}

                {enableDownload && (
                    <NavButton onClick={downloadAllFiles}>
                        <FileDownloadOutlinedIcon sx={{ fontSize: "23px" }} />
                    </NavButton>
                )}

                {(!onAddPhotos || enableJoin) && (
                    <SignUpButton
                        onClick={
                            enableJoin ? handleJoinAlbum : handleSignUpOrInstall
                        }
                    >
                        {buttonText}
                    </SignUpButton>
                )}
            </ButtonContainer>

            <Notification
                open={showCopiedMessage}
                onClose={() => setShowCopiedMessage(false)}
                horizontal="left"
                attributes={{
                    color: "secondary",
                    startIcon: <CheckIcon />,
                    title: "Copied!",
                }}
            />
        </>
    );
};

// Styled components
const ButtonContainer = styled(Box)({
    position: "fixed",
    top: "58px",
    right: "58px",
    display: "flex",
    gap: "8px",
    zIndex: 2000,
});

const NavButton = styled(IconButton)({
    padding: "12px",
    backgroundColor: "rgba(255, 255, 255, 0.9)",
    borderRadius: "8px",
    color: "#1f2937",
    transition: "background-color 0.2s",
    backdropFilter: "blur(10px)",
    boxShadow: "0 2px 8px rgba(0, 0, 0, 0.1)",
    width: "44px",
    height: "44px",
    "&:hover": { backgroundColor: "rgba(255, 255, 255, 1)" },
});

const SignUpButton = styled(Button)({
    padding: "12px 16px",
    marginLeft: "12px",
    fontSize: "16px",
    fontWeight: "600",
    whiteSpace: "nowrap",
    backgroundColor: "rgba(255, 255, 255, 0.9)",
    borderRadius: "8px",
    color: "#1f2937",
    transition: "background-color 0.2s",
    backdropFilter: "blur(10px)",
    boxShadow: "0 2px 8px rgba(0, 0, 0, 0.1)",
    "&:hover": { backgroundColor: "rgba(255, 255, 255, 1)" },
});
