import CloseIcon from "@mui/icons-material/Close";
import { IconButton, Stack, styled, Typography } from "@mui/material";
import { t } from "i18next";
import React, { useCallback, useEffect, useState } from "react";
import type { DropzoneState } from "react-dropzone";

interface FullScreenDropZoneProps {
    /**
     * The `getInputProps` function returned by a call to {@link useDropzone}.
     */
    getInputProps: DropzoneState["getInputProps"];
    /**
     * The `getRootProps` function returned by a call to {@link useDropzone}.
     */
    getRootProps: DropzoneState["getRootProps"];
    /**
     * Optional override to the message show to the user when a drag is in
     * progress.
     *
     * Default: t("upload_dropzone_hint")
     */
    message?: string;
}

/**
 * A full screen container that accepts drag and drop of files, and also shows a
 * visual overlay to the user while a drag is in progress.
 *
 * It can serves as the root component of the gallery pages as the container
 * itself is a stack with flex 1, and so will fill all the height (and width)
 * available to it. The other contents of the screen can then be placed as its
 * children.
 *
 * It is meant to be used in tandem with "react-dropzone"; specifically, it
 * requires the `getRootProps` function returned by a call to
 * {@link useDropzone}.
 */
export const FullScreenDropZone: React.FC<
    React.PropsWithChildren<FullScreenDropZoneProps>
> = ({ getInputProps, getRootProps, message, children }) => {
    const [isDragActive, setIsDragActive] = useState(false);

    const onDragEnter = useCallback(() => setIsDragActive(true), []);
    const onDragLeave = useCallback(() => setIsDragActive(false), []);

    useEffect(() => {
        const handleKeydown = (event: KeyboardEvent) => {
            if (event.code == "Escape") onDragLeave();
        };

        window.addEventListener("keydown", handleKeydown);
        return () => window.removeEventListener("keydown", handleKeydown);
    }, [onDragLeave]);

    return (
        <>
            <input {...getInputProps()} />
            <Stack sx={{ flex: 1 }} {...getRootProps({ onDragEnter })}>
                {isDragActive && (
                    <DropZoneOverlay
                        onDrop={onDragLeave}
                        onDragLeave={onDragLeave}
                    >
                        <CloseButton onClick={onDragLeave}>
                            <CloseIcon />
                        </CloseButton>
                        <Typography variant="h3">
                            {message ?? t("upload_dropzone_hint")}
                        </Typography>
                    </DropZoneOverlay>
                )}
                {children}
            </Stack>
        </>
    );
};

const DropZoneOverlay = styled(Stack)(
    ({ theme }) => `
    position: absolute;
    left: 0;
    top: 0;
    height: 100%;
    width: 100%;
    outline: none;
    justify-content: center;
    align-items: center;
    transition: border 0.24s ease-in-out;
    border-width: 5px;
    border-style: solid;
    border-color: ${theme.vars.palette.accent.light};
    background-color: ${theme.vars.palette.backdrop.base};
    z-index: 2000; /* aboveFileViewerContentZ + delta */
`,
);

const CloseButton = styled(IconButton)`
    position: absolute;
    top: 10px;
    right: 10px;
`;
