import DialogBoxV2 from "@ente/shared/components/DialogBoxV2";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { t } from "i18next";
import React from "react";

export interface CollectionNamerAttributes {
    callback: (name: string) => void;
    title: string;
    autoFilledName: string;
    buttonText: string;
}

export type SetCollectionNamerAttributes = React.Dispatch<
    React.SetStateAction<CollectionNamerAttributes>
>;

interface Props {
    show: boolean;
    onHide: () => void;
    attributes: CollectionNamerAttributes;
}

export default function CollectionNamer({ attributes, ...props }: Props) {
    if (!attributes) {
        return <></>;
    }
    const onSubmit: SingleInputFormProps["callback"] = async (
        albumName,
        setFieldError,
    ) => {
        try {
            attributes.callback(albumName);
            props.onHide();
        } catch (e) {
            setFieldError(t("generic_error_retry"));
        }
    };

    return (
        <DialogBoxV2
            open={props.show}
            onClose={props.onHide}
            attributes={{
                title: attributes.title,
            }}
        >
            <SingleInputForm
                callback={onSubmit}
                fieldType="text"
                buttonText={attributes.buttonText}
                placeholder={t("enter_album_name")}
                initialValue={attributes.autoFilledName}
                submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                secondaryButtonAction={props.onHide}
            />
        </DialogBoxV2>
    );
}
