import { DialogBoxV2 } from "@/base/components/MiniDialog";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { t } from "i18next";

export const FileNameEditDialog = ({
    isInEditMode,
    closeEditMode,
    filename,
    extension,
    saveEdits,
}) => {
    const onSubmit: SingleInputFormProps["callback"] = async (
        filename,
        setFieldError,
    ) => {
        try {
            await saveEdits(filename);
            closeEditMode();
        } catch (e) {
            setFieldError(t("generic_error_retry"));
        }
    };
    return (
        <DialogBoxV2
            sx={{ zIndex: 1600 }}
            open={isInEditMode}
            onClose={closeEditMode}
            attributes={{
                title: t("rename_file"),
            }}
        >
            <SingleInputForm
                initialValue={filename}
                callback={onSubmit}
                placeholder={t("enter_file_name")}
                buttonText={t("rename")}
                fieldType="text"
                caption={extension}
                secondaryButtonAction={closeEditMode}
                submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
            />
        </DialogBoxV2>
    );
};
