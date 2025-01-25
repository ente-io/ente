import { useCallback, useRef, useState } from "react";

interface UseFileInputParams {
    /**
     * If `true`, the file open dialog will ask the user to select directories.
     * Otherwise it'll ask the user to select files (default).
     */
    directory?: boolean;
    /**
     * If specified, it'll restrict the type of files that the user can select
     * by setting the "accept" attribute of the underlying HTML input element we
     * use to surface the file selector dialog. For value of accept can be an
     * extension or a MIME type (See
     * https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/accept).
     */
    accept?: string;
}

interface UseFileInputResult {
    /**
     * A function to call to get the properties that should be passed to a dummy
     * `input` element that needs to be created to anchor the select file
     * dialog. This input HTML element is not going to be visible, but it needs
     * to be part of the DOM for {@link openSelector} to have effect.
     */
    getInputProps: () => React.HTMLAttributes<HTMLInputElement>;
    /**
     * A function that can be called to open the select file / directory dialog.
     */
    openSelector: () => void;
    /**
     * The list of {@link File}s that the user selected.
     *
     * This will be a list even if the user selected directories - in that case,
     * it will be the recursive list of files within this directory.
     */
    selectedFiles: File[];
}

/**
 * Wrap a open file selector into an easy to use package.
 *
 * Returns a {@link UseFileInputResult} which contains a function to get the
 * props for an input element, a function to open the file selector, and the
 * list of selected files.
 *
 * See the documentation of {@link UseFileInputParams} and
 * {@link UseFileInputResult} for more details.
 */
export const useFileInput = ({
    directory,
    accept,
}: UseFileInputParams): UseFileInputResult => {
    const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
    const inputRef = useRef<HTMLInputElement | undefined>(undefined);

    const openSelector = useCallback(() => {
        if (inputRef.current) {
            inputRef.current.value = "";
            inputRef.current.click();
        }
    }, []);

    const handleChange: React.ChangeEventHandler<HTMLInputElement> = (
        event,
    ) => {
        const files = event.target.files;
        if (files) setSelectedFiles([...files]);
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
        [directoryOpts, accept, handleChange],
    );

    return { getInputProps, openSelector, selectedFiles };
};
