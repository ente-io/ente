import React from 'react';
import constants from 'utils/strings/constants';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import DialogBoxBase from 'components/DialogBox/base';
import { DialogContent, DialogTitle } from '@mui/material';

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
        <DialogBoxBase open={props.show} onClose={props.onHide}>
            <DialogTitle>{attributes.title}</DialogTitle>
            <DialogContent>
                <SingleInputForm
                    callback={onSubmit}
                    fieldType="text"
                    buttonText={attributes.buttonText}
                    placeholder={constants.ENTER_ALBUM_NAME}
                    initialValue={attributes.autoFilledName}
                    submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                    secondaryButtonAction={props.onHide}
                />
            </DialogContent>
        </DialogBoxBase>
    );
}
