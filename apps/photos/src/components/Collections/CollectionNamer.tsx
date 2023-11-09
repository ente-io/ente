import React from 'react';
import SingleInputForm, {
    SingleInputFormProps,
} from '@ente/shared/components/SingleInputForm';
import { t } from 'i18next';
import DialogBoxV2 from '@ente/shared/components/DialogBoxV2';

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
    const onSubmit: SingleInputFormProps['callback'] = async (
        albumName,
        setFieldError
    ) => {
        try {
            attributes.callback(albumName);
            props.onHide();
        } catch (e) {
            setFieldError(t('UNKNOWN_ERROR'));
        }
    };

    return (
        <DialogBoxV2
            open={props.show}
            onClose={props.onHide}
            attributes={{
                title: attributes.title,
            }}>
            <SingleInputForm
                callback={onSubmit}
                fieldType="text"
                buttonText={attributes.buttonText}
                placeholder={t('ENTER_ALBUM_NAME')}
                initialValue={attributes.autoFilledName}
                submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                secondaryButtonAction={props.onHide}
            />
        </DialogBoxV2>
    );
}
