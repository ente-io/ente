import React from 'react';
import constants from 'utils/strings/constants';
import DialogBox from 'components/DialogBox';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';

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
            setFieldError(constants.UNKNOWN_ERROR);
        }
    };

    return (
        <DialogBox
            open={props.show}
            attributes={{ title: attributes.title }}
            onClose={props.onHide}
            titleCloseButton
            maxWidth="xs">
            <SingleInputForm
                callback={onSubmit}
                fieldType="text"
                buttonText={attributes.buttonText}
                placeholder={constants.ENTER_ALBUM_NAME}
            />
        </DialogBox>
    );
}
