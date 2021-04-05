import React, { useEffect, useState } from 'react';
import Container from 'components/Container';
import styled from 'styled-components';
import Card from 'react-bootstrap/Card';
import Form from 'react-bootstrap/Form';
import Button from 'react-bootstrap/Button';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import * as Yup from 'yup';
import { KeyAttributes } from 'types';
import CryptoWorker, { setSessionKeys } from 'utils/crypto';
import { Spinner } from 'react-bootstrap';
import { propTypes } from 'react-bootstrap/esm/Image';

interface formValues {
    passphrase: string;
}
interface Props {
    callback: (passphrase: string, setFieldError) => void;
    title: string;
    placeholder: string;
    buttonText: string;
    alternateOption: { text: string; click: () => void };
    back: () => void;
}

export default function PassPhraseForm(props: Props) {
    const [loading, SetLoading] = useState(false);
    const submitForm = async (
        values: formValues,
        { setFieldError }: FormikHelpers<formValues>
    ) => {
        SetLoading(true);
        await props.callback(values.passphrase, setFieldError);
        SetLoading(false);
    };
    return (
        <Container>
            <Card
                style={{ minWidth: '320px', padding: '40px 30px' }}
                className="text-center"
            >
                <Card.Body>
                    <Card.Title style={{ marginBottom: '24px' }}>
                        {props.title}
                    </Card.Title>
                    <Formik<formValues>
                        initialValues={{ passphrase: '' }}
                        onSubmit={submitForm}
                        validationSchema={Yup.object().shape({
                            passphrase: Yup.string().required(
                                constants.REQUIRED
                            ),
                        })}
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
                                        type="text"
                                        placeholder={props.placeholder}
                                        value={values.passphrase}
                                        onChange={handleChange('passphrase')}
                                        onBlur={handleBlur('passphrase')}
                                        isInvalid={Boolean(
                                            touched.passphrase &&
                                                errors.passphrase
                                        )}
                                        disabled={loading}
                                        autoFocus={true}
                                    />
                                    <Form.Control.Feedback type="invalid">
                                        {errors.passphrase}
                                    </Form.Control.Feedback>
                                </Form.Group>
                                <Button block type="submit" disabled={loading}>
                                    {loading ? (
                                        <Spinner animation="border" />
                                    ) : (
                                        props.buttonText
                                    )}
                                </Button>
                                <br />
                                <div
                                    style={{
                                        display: 'flex',
                                        flexDirection: 'column',
                                    }}
                                >
                                    <Button
                                        variant="link"
                                        onClick={props.alternateOption.click}
                                    >
                                        {props.alternateOption.text}
                                    </Button>
                                    <Button variant="link" onClick={props.back}>
                                        {constants.GO_BACK}
                                    </Button>
                                </div>
                            </Form>
                        )}
                    </Formik>
                </Card.Body>
            </Card>
        </Container>
    );
}
