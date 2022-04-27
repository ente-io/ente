import React from 'react';
import { Dialog, DialogContent, TextField } from '@mui/material';
import constants from 'utils/strings/constants';
import SubmitButton from 'components/SubmitButton';
import { Formik } from 'formik';
import * as Yup from 'yup';
import { DialogTitleWithCloseButton } from 'components/MessageDialog';

export interface CollectionNamerAttributes {
    callback: (name) => void;
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
interface formValues {
    albumName: string;
}

export default function CollectionNamer({ attributes, ...props }: Props) {
    if (!attributes) {
        return <></>;
    }
    const onSubmit = ({ albumName }: formValues) => {
        attributes.callback(albumName);
        props.onHide();
    };

    return (
        <Dialog open={props.show} onClose={props.onHide} maxWidth="xs">
            <DialogTitleWithCloseButton onClose={props.onHide}>
                {attributes?.title}
            </DialogTitleWithCloseButton>
            <DialogContent>
                <Formik<formValues>
                    initialValues={{
                        albumName: attributes.autoFilledName ?? '',
                    }}
                    validationSchema={Yup.object().shape({
                        albumName: Yup.string().required(constants.REQUIRED),
                    })}
                    validateOnChange={false}
                    validateOnBlur={false}
                    onSubmit={onSubmit}>
                    {({
                        values,
                        touched,
                        errors,
                        handleChange,
                        handleSubmit,
                    }) => (
                        <form noValidate onSubmit={handleSubmit}>
                            <TextField
                                margin="normal"
                                fullWidth
                                type="text"
                                label={constants.ENTER_ALBUM_NAME}
                                value={values.albumName}
                                onChange={handleChange('albumName')}
                                autoFocus
                                required
                                error={
                                    touched.albumName &&
                                    Boolean(errors.albumName)
                                }
                                helperText={
                                    touched.albumName && errors.albumName
                                }
                            />
                            <SubmitButton
                                buttonText={attributes.buttonText}
                                loading={false}
                            />
                        </form>
                    )}
                </Formik>
            </DialogContent>
        </Dialog>
    );
}
