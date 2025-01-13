import { AppContext } from "@/new/photos/types/context";
import CloseIcon from "@mui/icons-material/Close";
import { styled } from "@mui/material";
import { t } from "i18next";
import React, { useContext, useEffect, useState } from "react";
import type { DropzoneState } from "react-dropzone";

interface FullScreenDropZoneProps {
    /**
     * The `getRootProps` function returned by a call to {@link useDropzone}.
     */
    getDragAndDropRootProps: DropzoneState["getRootProps"];
    /**
     * Optional override to the message show to the user when a drag is in
     * progress.
     *
     * Default: t("upload_dropzone_hint")
     */
    message?: string;
}

/**
 * A full screen overlay that accepts drag and drop of files, showing a visual
 * indicator to the user while a drag is in progress.
 *
 * It is meant to be used in tandem with "react-dropzone"; specifically, it
 * requires the `getRootProps` function returned by a call to
 * {@link useDropzone}.
 */
export const FullScreenDropZone: React.FC<
    React.PropsWithChildren<FullScreenDropZoneProps>
> = ({ getDragAndDropRootProps, children }) => {
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

    return (
        <DropDiv {...getDragAndDropRootProps({ onDragEnter })}>
            {isDragActive && (
                <Overlay onDrop={onDragLeave} onDragLeave={onDragLeave}>
                    <CloseButtonWrapper onClick={onDragLeave}>
                        <CloseIcon />
                    </CloseButtonWrapper>
                    {appContext!.watchFolderView
                        ? t("watch_folder_dropzone_hint")
                        : t("upload_dropzone_hint")}
                </Overlay>
            )}
            {children}
        </DropDiv>
    );
};

const DropDiv = styled("div")`
    flex: 1;
    display: flex;
    flex-direction: column;
    height: 100%;
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

const CloseButtonWrapper = styled("div")`
    position: absolute;
    top: 10px;
    right: 10px;
    cursor: pointer;
`;
