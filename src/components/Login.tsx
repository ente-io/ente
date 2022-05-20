import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import * as Yup from 'yup';
import { getOtt } from 'services/userService';
import { setData, LS_KEYS, getData } from 'utils/storage/localStorage';
import SubmitButton from 'components/SubmitButton';
import { PAGES } from 'constants/pages';
import FormPaperTitle from './Form/FormPaper/Title';
import { Divider, TextField } from '@mui/material';
import FormPaperFooter from './Form/FormPaper/Footer';
import LinkButton from './pages/gallery/LinkButton';

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

    return (
        <>
            <FormPaperTitle>{constants.LOGIN}</FormPaperTitle>
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
                {({ values, errors, handleChange, handleSubmit }) => (
                    <form noValidate onSubmit={handleSubmit}>
                        <TextField
                            fullWidth
                            type="email"
                            label={constants.ENTER_EMAIL}
                            value={values.email}
                            onChange={handleChange('email')}
                            error={Boolean(errors.email)}
                            helperText={errors.email}
                            autoFocus
                            disabled={loading}
                        />

                        <SubmitButton
                            sx={{ mb: 4 }}
                            buttonText={constants.LOGIN}
                            loading={waiting}
                        />
                    </form>
                )}
            </Formik>
            <Divider />
            <FormPaperFooter>
                <LinkButton onClick={props.signUp}>
                    {constants.NO_ACCOUNT}
                </LinkButton>
            </FormPaperFooter>
        </>
    );
}
