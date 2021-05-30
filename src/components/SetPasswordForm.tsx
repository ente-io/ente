import React, { useState } from 'react';
import Container from 'components/Container';
import Card from 'react-bootstrap/Card';
import Form from 'react-bootstrap/Form';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import Button from 'react-bootstrap/Button';
import SubmitButton from './SubmitButton';

interface Props {
    callback: (passphrase: any, setFieldError: any) => Promise<void>;
    buttonText: string;
    back: () => void;
}
interface formValues {
    passphrase: string;
    confirm: string;
}
function SetPasswordForm(props: Props) {
    const [loading, setLoading] = useState(false);
    const onSubmit = async (
        values: formValues,
        { setFieldError }: FormikHelpers<formValues>,
    ) => {
        setLoading(true);
        try {
            const { passphrase, confirm } = values;
            if (passphrase === confirm) {
                await props.callback(passphrase, setFieldError);
            } else {
                setFieldError('confirm', constants.PASSPHRASE_MATCH_ERROR);
            }
        } catch (e) {
            setFieldError(
                'passphrase',
                `${constants.UNKNOWN_ERROR} ${e.message}`,
            );
        } finally {
            setLoading(false);
        }
    };
    return (
        <Container>
            <Card style={{ maxWidth: '540px', padding: '20px' }}>
                <Card.Body>
                    <div
                        className="text-center"
                        style={{ marginBottom: '40px' }}
                    >
                        <p>{constants.ENTER_ENC_PASSPHRASE}</p>
                        {constants.PASSPHRASE_DISCLAIMER()}
                    </div>
                    <Formik<formValues>
                        initialValues={{ passphrase: '', confirm: '' }}
                        validationSchema={Yup.object().shape({
                            passphrase: Yup.string().required(
                                constants.REQUIRED,
                            ),
                            confirm: Yup.string().required(constants.REQUIRED),
                        })}
                        validateOnChange={false}
                        validateOnBlur={false}
                        onSubmit={onSubmit}
                    >
                        {({
                            values,
                            touched,
                            errors,
                            handleChange,
                            handleSubmit,
                        }) => (
                            <Form noValidate onSubmit={handleSubmit}>
                                <Form.Group>
                                    <Form.Control
                                        type="password"
                                        placeholder={constants.PASSPHRASE_HINT}
                                        value={values.passphrase}
                                        onChange={handleChange('passphrase')}
                                        isInvalid={Boolean(
                                            touched.passphrase &&
                                                errors.passphrase,
                                        )}
                                        autoFocus
                                        disabled={loading}
                                    />
                                    <Form.Control.Feedback type="invalid">
                                        {errors.passphrase}
                                    </Form.Control.Feedback>
                                </Form.Group>
                                <Form.Group>
                                    <Form.Control
                                        type="password"
                                        placeholder={
                                            constants.RE_ENTER_PASSPHRASE
                                        }
                                        value={values.confirm}
                                        onChange={handleChange('confirm')}
                                        isInvalid={Boolean(
                                            touched.confirm && errors.confirm,
                                        )}
                                        disabled={loading}
                                    />
                                    <Form.Control.Feedback type="invalid">
                                        {errors.confirm}
                                    </Form.Control.Feedback>
                                </Form.Group>
                                <SubmitButton
                                    buttonText={props.buttonText}
                                    loading={loading}
                                />
                            </Form>
                        )}
                    </Formik>
                    {props.back && (
                        <div
                            className="text-center"
                            style={{ marginTop: '20px' }}
                        >
                            <Button variant="link" onClick={props.back}>
                                {constants.GO_BACK}
                            </Button>
                        </div>
                    )}
                </Card.Body>
            </Card>
        </Container>
    );
}
export default SetPasswordForm;
