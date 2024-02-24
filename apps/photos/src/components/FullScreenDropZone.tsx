import CloseIcon from "@mui/icons-material/Close";
import { styled } from "@mui/material";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import React, { useContext, useEffect, useState } from "react";

const CloseButtonWrapper = styled("div")`
    position: absolute;
    top: 10px;
    right: 10px;
    cursor: pointer;
`;
const DropDiv = styled("div")`
    flex: 1;
    display: flex;
    flex-direction: column;
`;
const Overlay = styled("div")`
    border-width: 8px;
    left: 0;
    top: 0;
    outline: none;
    transition: border 0.24s ease-in-out;
    height: 100%;
    width: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    font-size: 24px;
    font-weight: 900;
    text-align: center;
    position: absolute;
    border-color: #51cd7c;
    border-style: solid;
    background: rgba(0, 0, 0, 0.9);
    z-index: 3000;
`;

type Props = React.PropsWithChildren<{
    getDragAndDropRootProps: any;
}>;

export default function FullScreenDropZone(props: Props) {
    const appContext = useContext(AppContext);

    const [isDragActive, setIsDragActive] = useState(false);
    const onDragEnter = () => setIsDragActive(true);
    const onDragLeave = () => setIsDragActive(false);

    useEffect(() => {
        window.addEventListener("keydown", (event) => {
            if (event.code === "Escape") {
                onDragLeave();
            }
        });
    }, []);

    useEffect(() => {
        const handleWatchFolderDrop = (e: DragEvent) => {
            if (!appContext.watchFolderView) {
                return;
            }

            e.preventDefault();
            e.stopPropagation();
            const files = e.dataTransfer.files;
            if (files.length > 0) {
                appContext.setWatchFolderFiles(files);
            }
        };

        addEventListener("drop", handleWatchFolderDrop);
        return () => {
            removeEventListener("drop", handleWatchFolderDrop);
        };
    }, [appContext.watchFolderView]);

    return (
        <DropDiv
            {...props.getDragAndDropRootProps({
                onDragEnter,
            })}
        >
            {isDragActive && (
                <Overlay onDrop={onDragLeave} onDragLeave={onDragLeave}>
                    <CloseButtonWrapper onClick={onDragLeave}>
                        <CloseIcon />
                    </CloseButtonWrapper>
                    {appContext.watchFolderView
                        ? t("WATCH_FOLDER_DROPZONE_MESSAGE")
                        : t("UPLOAD_DROPZONE_MESSAGE")}
                </Overlay>
            )}
            {props.children}
        </DropDiv>
    );
}
