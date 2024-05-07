import { useCallback, useRef, useState } from "react";

interface UseFileInputParams {
    directory?: boolean;
    accept?: string;
}

/**
 * Return three things:
 *
 * - A function that can be called to trigger the showing of the select file /
 *   directory dialog.
 *
 * - The list of properties that should be passed to a dummy `input` element
 *   that needs to be created to anchor the select file dialog. This input HTML
 *   element is not going to be visible, but it needs to be part of the DOM fro
 *   the open trigger to have effect.
 *
 * - The list of files that the user selected. This will be a list even if the
 *   user selected directories - in that case, it will be the recursive list of
 *   files within this directory.
 *
 * @param param0
 *
 * - If {@link directory} is true, the file open dialog will ask the user to
 *   select directories. Otherwise it'll ask the user to select files.
 *
 * - If {@link accept} is specified, it'll restrict the type of files that the
 *   user can select by setting the "accept" attribute of the underlying HTML
 *   input element we use to surface the file selector dialog. For value of
 *   accept can be an extension or a MIME type (See
 *   https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/accept).
 */
export default function useFileInput({
    directory,
    accept,
}: UseFileInputParams) {
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
            setSelectedFiles([...event.target.files]);
        }
    };

    // [Note: webkitRelativePath]
    //
    // If the webkitdirectory attribute of an <input> HTML element is set then
    // the File objects that we get will have `webkitRelativePath` property
    // containing the relative path to the selected directory.
    //
    // https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/webkitdirectory
    //
    // These paths use the POSIX path separator ("/").
    // https://stackoverflow.com/questions/62806233/when-using-webkitrelativepath-is-the-path-separator-operating-system-specific
    //
    const directoryOpts = directory
        ? { directory: "", webkitdirectory: "" }
        : {};

    const getInputProps = useCallback(
        () => ({
            type: "file",
            multiple: true,
            style: { display: "none" },
            ...directoryOpts,
            ref: inputRef,
            onChange: handleChange,
            ...(accept ? { accept } : {}),
        }),
        [],
    );

    return {
        getInputProps,
        open: openSelectorDialog,
        selectedFiles: selectedFiles,
    };
}
