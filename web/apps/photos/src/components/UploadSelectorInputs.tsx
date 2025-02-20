type GetInputProps = () => React.HTMLAttributes<HTMLInputElement>;

interface UploadSelectorInputsProps {
    // getDragAndDropInputProps: GetInputProps;
    getFileSelectorInputProps: GetInputProps;
    getFolderSelectorInputProps: GetInputProps;
    getZipFileSelectorInputProps?: GetInputProps;
}

/**
 * Create a bunch of HTML inputs elements, one each for the given props.
 *
 * These hidden input element serve as the way for us to show various file /
 * folder Selector dialogs and handle drag and drop inputs.
 */
export const UploadSelectorInputs: React.FC<UploadSelectorInputsProps> = ({
    // getDragAndDropInputProps,
    getFileSelectorInputProps,
    getFolderSelectorInputProps,
    getZipFileSelectorInputProps,
}) => {
    return (
        <>
            {/* <input {...getDragAndDropInputProps()} /> */}
            <input {...getFileSelectorInputProps()} />
            <input {...getFolderSelectorInputProps()} />
            {getZipFileSelectorInputProps && (
                <input {...getZipFileSelectorInputProps()} />
            )}
        </>
    );
};
