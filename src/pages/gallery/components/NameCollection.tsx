import React, { useEffect, useRef } from 'react';
import { Modal, Form } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import { UPLOAD_STRATEGY } from './Upload';
import { Formik } from 'formik';
import * as Yup from 'yup';
import SubmitButton from 'components/SubmitButton';

interface Props {
    show: boolean;
    onHide: () => void;
    autoFilledName: string;
    callback: any;
    purpose: { title: string; buttonText: string };
}
interface formValues {
    albumName: string;
}
export default function NameCollection(props: Props) {
    const collectionNameInputRef = useRef(null);

    const onSubmit = ({ albumName }: formValues) => {
        props.callback(albumName);
        props.onHide();
    };

    useEffect(() => {
        setTimeout(() => {
            collectionNameInputRef.current?.focus();
        }, 200);
    }, [props.show]);
    return (
        <Modal
            show={props.show}
            onHide={props.onHide}
            centered
            backdrop="static"
            style={{ background: 'rgba(0, 0, 0, 0.8)' }}
            dialogClassName="ente-modal"
        >
            <Modal.Header closeButton>
                <Modal.Title>{props.purpose.title}</Modal.Title>
            </Modal.Header>
            <Modal.Body>
                <Formik<formValues>
                    initialValues={{ albumName: props.autoFilledName }}
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
                                buttonText={props.purpose.buttonText}
                                loading={false}
                            />
                        </Form>
                    )}
                </Formik>
            </Modal.Body>
        </Modal>
    );
}
