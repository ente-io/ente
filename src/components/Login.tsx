import Card from 'react-bootstrap/Card';
import Form from 'react-bootstrap/Form';
import FormControl from 'react-bootstrap/FormControl';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import React, { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/router';
import * as Yup from 'yup';
import { getOtt } from 'services/userService';
import { setData, LS_KEYS, getData } from 'utils/storage/localStorage';
import SubmitButton from 'components/SubmitButton';
import Button from 'react-bootstrap/Button';
import LogoImg from './LogoImg';
import { PAGES } from 'types';

interface formValues {
    email: string;
}

interface LoginProps {
    signUp: () => void;
}

export default function Login(props: LoginProps) {
    const router = useRouter();
    const [waiting, setWaiting] = useState(false);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const main = async () => {
            router.prefetch(PAGES.VERIFY);
            const user = getData(LS_KEYS.USER);
            if (user?.email) {
                await router.push(PAGES.VERIFY);
            }
            setLoading(false);
        };
        main();
    }, []);

    const loginUser = async (
        { email }: formValues,
        { setFieldError }: FormikHelpers<formValues>
    ) => {
        try {
            setWaiting(true);
            await getOtt(email);
            setData(LS_KEYS.USER, { email });
            router.push(PAGES.VERIFY);
        } catch (e) {
            setFieldError('email', `${constants.UNKNOWN_ERROR} ${e.message}`);
        }
        setWaiting(false);
    };
    const inputElement = useRef(null);
    useEffect(() => {
        setTimeout(() => {
            inputElement.current?.focus();
        }, 250);
    }, []);

    return (
        <>
            <Card.Title style={{ marginBottom: '32px' }}>
                <LogoImg src="/icon.svg" />
                {constants.LOGIN}
            </Card.Title>
            <Formik<formValues>
                initialValues={{ email: '' }}
                validationSchema={Yup.object().shape({
                    email: Yup.string()
                        .email(constants.EMAIL_ERROR)
                        .required(constants.REQUIRED),
                })}
                validateOnChange={false}
                validateOnBlur={false}
                onSubmit={loginUser}>
                {({ values, errors, touched, handleChange, handleSubmit }) => (
                    <Form noValidate onSubmit={handleSubmit}>
                        <Form.Group controlId="formBasicEmail">
                            <Form.Control
                                ref={inputElement}
                                type="email"
                                placeholder={constants.ENTER_EMAIL}
                                value={values.email}
                                onChange={handleChange('email')}
                                isInvalid={Boolean(
                                    touched.email && errors.email
                                )}
                                autoFocus
                                disabled={loading}
                            />
                            <FormControl.Feedback type="invalid">
                                {errors.email}
                            </FormControl.Feedback>
                        </Form.Group>
                        <SubmitButton
                            buttonText={constants.LOGIN}
                            loading={waiting}
                        />
                        <br />
                        <Button
                            block
                            variant="link"
                            className="text-center"
                            onClick={props.signUp}>
                            {constants.NO_ACCOUNT}
                        </Button>
                    </Form>
                )}
            </Formik>
        </>
    );
}
