import AddPhotoAlternateOutlinedIcon from "@mui/icons-material/AddPhotoAlternateOutlined";
import CheckIcon from "@mui/icons-material/Check";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import ShareIcon from "@mui/icons-material/Share";
import { Box, Button, IconButton, styled } from "@mui/material";
import { FeedIcon } from "components/Collections/CollectionHeader";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { useIsTouchscreen } from "ente-base/components/utils/hooks";
import type { PublicAlbumsCredentials } from "ente-base/http";
import type { Collection } from "ente-media/collection";
import { Notification } from "ente-new/photos/components/Notification";
import { useJoinAlbum } from "hooks/useJoinAlbum";
import { t } from "i18next";
import { useState } from "react";
import { getSignUpOrInstallURL } from "utils/public-album";

interface MobileNavBarProps {
    onAddPhotos?: () => void;
    downloadAllFiles: () => void;
    enableDownload?: boolean;
    onShowFeed?: () => void;
    collectionTitle?: string;
    publicCollection?: Collection;
    accessToken?: string;
    collectionKey?: string;
    credentials?: React.RefObject<PublicAlbumsCredentials | undefined>;
}

export const MobileNavBar: React.FC<MobileNavBarProps> = ({
    onAddPhotos,
    downloadAllFiles,
    enableDownload,
    onShowFeed,
    collectionTitle,
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

    const handleShare = async () => {
        if (typeof window !== "undefined") {
            const albumName = collectionTitle || "Trip";
            const shareUrl = window.location.href;
            const shareText = `${albumName}\n${shareUrl}`;

            try {
                await navigator.share({ text: shareText });
            } catch (error) {
                if (
                    !error ||
                    (error instanceof Error && error.name !== "AbortError")
                ) {
                    void navigator.clipboard.writeText(shareText);
                    setShowCopiedMessage(true);
                    setTimeout(() => setShowCopiedMessage(false), 2000);
                }
            }
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
            <MobileNavContainer>
                <LogoContainer>
                    <EnteLogo />
                </LogoContainer>

                <ButtonGroup>
                    <MobileNavButton onClick={handleShare}>
                        <ShareIcon sx={{ fontSize: "15px" }} />
                    </MobileNavButton>

                    {onShowFeed && (
                        <MobileNavButton onClick={onShowFeed}>
                            <FeedIcon />
                        </MobileNavButton>
                    )}

                    {onAddPhotos && (
                        <MobileNavButton onClick={onAddPhotos}>
                            <AddPhotoAlternateOutlinedIcon
                                sx={{ fontSize: "16px" }}
                            />
                        </MobileNavButton>
                    )}

                    {enableDownload && (
                        <MobileNavButton onClick={downloadAllFiles}>
                            <FileDownloadOutlinedIcon
                                sx={{ fontSize: "18px" }}
                            />
                        </MobileNavButton>
                    )}

                    {(!onAddPhotos || enableJoin) && (
                        <MobileSignUpButton
                            onClick={
                                enableJoin
                                    ? handleJoinAlbum
                                    : handleSignUpOrInstall
                            }
                        >
                            {buttonText}
                        </MobileSignUpButton>
                    )}
                </ButtonGroup>
            </MobileNavContainer>

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

const MobileNavContainer = styled(Box)({
    position: "fixed",
    top: 0,
    left: 0,
    right: 0,
    height: "60px",
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    padding: "0 16px",
    backgroundColor: "transparent",
    zIndex: 2000,
    "&::after": {
        content: '""',
        position: "absolute",
        top: 0,
        left: 0,
        right: 0,
        height: "90px",
        background:
            "linear-gradient(180deg, rgba(0, 0, 0, 0.7) 0%, transparent 100%)",
        zIndex: -1,
        pointerEvents: "none",
    },
});

const LogoContainer = styled(Box)({
    display: "flex",
    alignItems: "center",
    "& svg": { height: "20px", width: "auto" },
});

const ButtonGroup = styled(Box)({
    display: "flex",
    alignItems: "center",
    gap: "8px",
});

const MobileNavButton = styled(IconButton)({
    padding: "6px",
    backgroundColor: "rgba(255, 255, 255, 0.9)",
    borderRadius: "6px",
    color: "#000000",
    transition: "background-color 0.2s",
    backdropFilter: "blur(10px)",
    width: "32px",
    height: "32px",
    boxShadow: "0 2px 8px rgba(0, 0, 0, 0.1)",
    "&:hover": { backgroundColor: "rgba(255, 255, 255, 1)" },
});

const MobileSignUpButton = styled(Button)({
    padding: "6px 10px",
    fontSize: "13px",
    fontWeight: "600",
    whiteSpace: "nowrap",
    backgroundColor: "rgba(255, 255, 255, 0.9)",
    borderRadius: "6px",
    color: "#000000",
    transition: "background-color 0.2s",
    backdropFilter: "blur(10px)",
    boxShadow: "0 2px 8px rgba(0, 0, 0, 0.1)",
    "&:hover": { backgroundColor: "rgba(255, 255, 255, 1)" },
});
