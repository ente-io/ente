import { useCallback, useRef, useState } from "react";

/**
 * TODO (MR): Understand how this is happening, and validate it further (on
 * first glance this is correct).
 *
 * [Note: File paths when running under Electron]
 *
 * We have access to the absolute path of the web {@link File} object when we
 * are running in the context of our desktop app.
 *
 * This is in contrast to the `webkitRelativePath` that we get when we're
 * running in the browser, which is the relative path to the directory that the
 * user selected (or just the name of the file if the user selected or
 * drag/dropped a single one).
 */
export interface FileWithPath extends File {
    readonly path?: string;
}

export default function useFileInput({ directory }: { directory?: boolean }) {
    const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
    const inputRef = useRef<HTMLInputElement>();

    const openSelectorDialog = useCallback(() => {
        if (inputRef.current) {
            inputRef.current.value = null;
            inputRef.current.click();
        }
    }, []);

    const handleChange: React.ChangeEventHandler<HTMLInputElement> = async (
        event,
    ) => {
        if (!!event.target && !!event.target.files) {
            const files = [...event.target.files].map((file) =>
                toFileWithPath(file),
            );
            setSelectedFiles(files);
        }
    };

    const getInputProps = useCallback(
        () => ({
            type: "file",
            multiple: true,
            style: { display: "none" },
            ...(directory ? { directory: "", webkitdirectory: "" } : {}),
            ref: inputRef,
            onChange: handleChange,
        }),
        [],
    );

    return {
        getInputProps,
        open: openSelectorDialog,
        selectedFiles: selectedFiles,
    };
}

// https://github.com/react-dropzone/file-selector/blob/master/src/file.ts#L88
export function toFileWithPath(file: File, path?: string): FileWithPath {
    if (typeof (file as any).path !== "string") {
        // on electron, path is already set to the absolute path
        const { webkitRelativePath } = file;
        Object.defineProperty(file, "path", {
            value:
                typeof path === "string"
                    ? path
                    : typeof webkitRelativePath === "string" && // If <input webkitdirectory> is set,
                        // the File will have a {webkitRelativePath} property
                        // https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/webkitdirectory
                        webkitRelativePath.length > 0
                      ? webkitRelativePath
                      : file.name,
            writable: false,
            configurable: false,
            enumerable: true,
        });
    }
    return file;
}
