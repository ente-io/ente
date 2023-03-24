import React, { useEffect } from 'react';
import { useRouter } from 'next/router';
import { sendOtt } from 'services/userService';
import { setData, LS_KEYS, getData } from 'utils/storage/localStorage';
import { PAGES } from 'constants/pages';
import FormPaperTitle from './Form/FormPaper/Title';
import FormPaperFooter from './Form/FormPaper/Footer';
import LinkButton from './pages/gallery/LinkButton';
import SingleInputForm, { SingleInputFormProps } from './SingleInputForm';
import { Input } from '@mui/material';
import { t } from 'i18next';

interface LoginProps {
    signUp: () => void;
}

export default function Login(props: LoginProps) {
    const router = useRouter();

    useEffect(() => {
        const main = async () => {
            router.prefetch(PAGES.VERIFY);
            const user = getData(LS_KEYS.USER);
            if (user?.email) {
                await router.push(PAGES.VERIFY);
            }
        };
        main();
    }, []);

    const loginUser: SingleInputFormProps['callback'] = async (
        email,
        setFieldError
    ) => {
        try {
            await sendOtt(email);
            setData(LS_KEYS.USER, { email });
            router.push(PAGES.VERIFY);
        } catch (e) {
            setFieldError(`${t('UNKNOWN_ERROR} ${e.message}')}`);
        }
    };

    return (
        <>
            <FormPaperTitle>{t('LOGIN')}</FormPaperTitle>
            <SingleInputForm
                callback={loginUser}
                fieldType="email"
                placeholder={t('ENTER_EMAIL')}
                buttonText={t('LOGIN')}
                autoComplete="username"
                hiddenPostInput={<Input hidden type="password" value="" />}
            />

            <FormPaperFooter>
                <LinkButton onClick={props.signUp}>
                    {t('NO_ACCOUNT')}
                </LinkButton>
            </FormPaperFooter>
        </>
    );
}
