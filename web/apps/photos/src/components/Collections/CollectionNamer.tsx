import { TitledMiniDialog } from "@/base/components/MiniDialog";
import log from "@/base/log";
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
            log.error(e);
            setFieldError(t("generic_error_retry"));
        }
    };

    return (
        <TitledMiniDialog
            open={props.show}
            onClose={props.onHide}
            title={attributes.title}
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
        </TitledMiniDialog>
    );
}
