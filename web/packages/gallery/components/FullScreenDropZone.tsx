import CloseIcon from "@mui/icons-material/Close";
import { Stack, styled } from "@mui/material";
import { t } from "i18next";
import React, { useCallback, useEffect, useState } from "react";
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
> = ({ getDragAndDropRootProps, message, children }) => {
    const [isDragActive, setIsDragActive] = useState(false);

    const onDragEnter = useCallback(() => setIsDragActive(true), []);
    const onDragLeave = useCallback(() => setIsDragActive(false), []);

    useEffect(() => {
        const handleKeydown = (event: KeyboardEvent) => {
            if (event.code === "Escape") {
                onDragLeave();
            }
        };

        window.addEventListener("keydown", handleKeydown);
        return () => window.removeEventListener("keydown", handleKeydown);
    }, [onDragLeave]);

    return (
        <DropDiv {...getDragAndDropRootProps({ onDragEnter })}>
            {isDragActive && (
                <Overlay onDrop={onDragLeave} onDragLeave={onDragLeave}>
                    <CloseButtonWrapper onClick={onDragLeave}>
                        <CloseIcon />
                    </CloseButtonWrapper>
                    {message ?? t("upload_dropzone_hint")}
                </Overlay>
            )}
            {children}
        </DropDiv>
    );
};

const DropDiv = styled(Stack)`
    flex: 1;
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
