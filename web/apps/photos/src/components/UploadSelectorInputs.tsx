export default function UploadSelectorInputs({
    getDragAndDropInputProps,
    getFileSelectorInputProps,
    getFolderSelectorInputProps,
}) {
    return (
        <>
            <input {...getDragAndDropInputProps()} />
            <input {...getFileSelectorInputProps()} />
            <input {...getFolderSelectorInputProps()} />
        </>
    );
}
