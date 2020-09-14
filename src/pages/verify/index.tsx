import React, { useState, useEffect } from 'react';
import Container from 'components/Container';
import Card from 'react-bootstrap/Card';
import Form from 'react-bootstrap/Form';
import Button from 'react-bootstrap/Button';
import constants from 'utils/strings/constants';
import styled from 'styled-components';
import { LS_KEYS, getData, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import { verifyOtt, getOtt } from 'services/userService';

const Image = styled.img`
    width: 350px;
    margin-bottom: 20px;
    max-width: 100%;
`;

interface formValues {
    ott: string;
}

export default function Verify() {
    const [email, setEmail] = useState('');
    const [loading, setLoading] = useState(false);
    const [resend, setResend] = useState(0);
    const router = useRouter();
    
    useEffect(() => {
        router.prefetch('/credentials');
        router.prefetch('/generate');
        const user = getData(LS_KEYS.USER);
        if (!user?.email) {
            router.push("/");
        } else if (user.token) { 
            router.push("/credentials")
        } else {
            setEmail(user.email);
        }
    }, []);

    const onSubmit = async ({ ott }: formValues, { setFieldError }: FormikHelpers<formValues>) => {
        try {
            setLoading(true);
            const resp = await verifyOtt(email, ott);
            setData(LS_KEYS.USER, {
                email,
                token: resp.data.token,
            });
            setData(LS_KEYS.KEY_ATTRIBUTES, resp.data.keyAttributes);
            if (resp.data.keyAttributes?.encryptedKey) {
                router.push("/credentials");
            } else {
                router.push("/generate");
            }
        } catch (e) {
            if (e?.response?.status === 401) {
                setFieldError('ott', constants.INVALID_CODE);
            } else {
                setFieldError('ott', `${constants.UNKNOWN_ERROR} ${e.message}`);
            }
        }
        setLoading(false);
    }

    const resendEmail = async () => {
        setResend(1);
        const resp = await getOtt(email);
        setResend(2);
        setTimeout(() => setResend(0), 3000);
    }

    if (!email) {
        return null;
    }

    return (<Container>
        <Image alt='Email Sent' src='/email_sent.svg' />
        <Card style={{ minWidth: '300px' }} className="text-center">
            <Card.Body>
                <Card.Title>{constants.VERIFY_EMAIL}</Card.Title>
                {constants.EMAIL_SENT({ email })}
                {constants.CHECK_INBOX}<br />
                <br/>
                <Formik<formValues>
                    initialValues={{ ott: '' }}
                    validationSchema={Yup.object().shape({
                        ott: Yup.string().required(constants.REQUIRED),
                    })}
                    onSubmit={onSubmit}
                >
                    {({ values, touched, errors, handleChange, handleBlur, handleSubmit }) => (
                        <Form noValidate onSubmit={handleSubmit}>
                            <Form.Group>
                                <Form.Control
                                    className="text-center"
                                    type='text'
                                    value={values.ott}
                                    onChange={handleChange('ott')}
                                    onBlur={handleBlur('ott')}
                                    isInvalid={Boolean(touched.ott && errors.ott)}
                                    placeholder={constants.ENTER_OTT}
                                    disabled={loading}
                                />
                                <Form.Control.Feedback type='invalid'>
                                    {errors.ott}
                                </Form.Control.Feedback>
                            </Form.Group>
                            <Button type="submit" block disabled={loading}>{constants.VERIFY}</Button>
                            <br/>
                            {resend === 0 && <a href="#" onClick={resendEmail}>{constants.RESEND_MAIL}</a>}
                            {resend === 1 && <span>{constants.SENDING}</span>}
                            {resend === 2 && <span>{constants.SENT}</span>}
                        </Form>
                    )}
                </Formik>
            </Card.Body>
        </Card>
    </Container>)
}