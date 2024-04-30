export default function UploadSelectorInputs({
    getDragAndDropInputProps,
    getFileSelectorInputProps,
    getFolderSelectorInputProps,
    getZipFileSelectorInputProps,
}) {
    return (
        <>
            <input {...getDragAndDropInputProps()} />
            <input {...getFileSelectorInputProps()} />
            <input {...getFolderSelectorInputProps()} />
            {getZipFileSelectorInputProps && (
                <input {...getZipFileSelectorInputProps()} />
            )}
        </>
    );
}
