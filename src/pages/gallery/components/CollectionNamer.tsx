import React, { useEffect, useRef } from 'react';
import { Modal, Form } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import { UPLOAD_STRATEGY } from './Upload';
import { Formik } from 'formik';
import * as Yup from 'yup';
import SubmitButton from 'components/SubmitButton';
import MessageDialog from 'components/MessageDialog';

interface Props {
    show: boolean;
    onHide: () => void;
    attributes: CollectionNamerAttributes;
}
interface formValues {
    albumName: string;
}
export interface CollectionNamerAttributes {
    callback: (name) => Promise<void>;
    title: string;
    autoFilledName: string;
    buttonText: string;
}

export type SetCollectionNamerAttributes = React.Dispatch<
    React.SetStateAction<CollectionNamerAttributes>
>;

export default function CollectionNamer({ attributes, ...props }: Props) {
    const collectionNameInputRef = useRef(null);

    const onSubmit = ({ albumName }: formValues) => {
        attributes.callback(albumName);
        props.onHide();
    };

    useEffect(() => {
        setTimeout(() => {
            collectionNameInputRef.current?.focus();
        }, 200);
    }, [props.show]);
    if (!attributes) {
        return (
            <MessageDialog show={false} onHide={() => null} attributes={{}} />
        );
    }
    return (
        <MessageDialog
            show={props.show}
            onHide={props.onHide}
            size={'sm'}
            attributes={{
                title: attributes?.title,
            }}
        >
            <Formik<formValues>
                initialValues={{ albumName: attributes.autoFilledName }}
                validationSchema={Yup.object().shape({
                    albumName: Yup.string().required(constants.REQUIRED),
                })}
                onSubmit={onSubmit}
            >
                {({
                    values,
                    touched,
                    errors,
                    handleChange,
                    handleBlur,
                    handleSubmit,
                }) => (
                    <Form noValidate onSubmit={handleSubmit}>
                        <Form.Group>
                            <Form.Control
                                className="text-center"
                                type="text"
                                value={values.albumName}
                                onChange={handleChange('albumName')}
                                onBlur={handleBlur('albumName')}
                                isInvalid={Boolean(
                                    touched.albumName && errors.albumName
                                )}
                                placeholder={constants.ENTER_ALBUM_NAME}
                                ref={collectionNameInputRef}
                                autoFocus={true}
                            />

                            <Form.Control.Feedback
                                type="invalid"
                                className="text-center"
                            >
                                {errors.albumName}
                            </Form.Control.Feedback>
                        </Form.Group>
                        <SubmitButton
                            buttonText={attributes.buttonText}
                            loading={false}
                        />
                    </Form>
                )}
            </Formik>
        </MessageDialog>
    );
}
