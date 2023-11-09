import { useCallback, useRef, useState } from 'react';

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
        event
    ) => {
        if (!!event.target && !!event.target.files) {
            const files = [...event.target.files].map((file) =>
                toFileWithPath(file)
            );
            setSelectedFiles(files);
        }
    };

    const getInputProps = useCallback(
        () => ({
            type: 'file',
            multiple: true,
            style: { display: 'none' },
            ...(directory ? { directory: '', webkitdirectory: '' } : {}),
            ref: inputRef,
            onChange: handleChange,
        }),
        []
    );

    return {
        getInputProps,
        open: openSelectorDialog,
        selectedFiles: selectedFiles,
    };
}

// https://github.com/react-dropzone/file-selector/blob/master/src/file.ts#L88
export function toFileWithPath(file: File, path?: string): FileWithPath {
    if (typeof (file as any).path !== 'string') {
        // on electron, path is already set to the absolute path
        const { webkitRelativePath } = file;
        Object.defineProperty(file, 'path', {
            value:
                typeof path === 'string'
                    ? path
                    : typeof webkitRelativePath === 'string' && // If <input webkitdirectory> is set,
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
