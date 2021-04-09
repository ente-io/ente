import React, { useEffect, useState } from 'react';
import Container from 'components/Container';
import Button from 'react-bootstrap/Button';
import constants from 'utils/strings/constants';
import { Card, Form, Spinner } from 'react-bootstrap';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';

interface formValues {
    passphrase: string;
}
interface Props {
    callback: (passphrase: string, setFieldError) => void;
    fieldType: string;
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
                                        type={props.fieldType}
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
                                <Button
                                    variant="success"
                                    block
                                    type="submit"
                                    disabled={loading}
                                >
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
