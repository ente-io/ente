import { useRouter } from 'next/router';
import { getSRPAttributes } from '../api/srp';
import { sendOtt } from '../api/user';
import { setData, LS_KEYS } from '@ente/shared/storage/localStorage';
import { PAGES } from '../constants/pages';
import FormPaperTitle from '@ente/shared/components/Form/FormPaper/Title';
import FormPaperFooter from '@ente/shared/components/Form/FormPaper/Footer';
import LinkButton from '@ente/shared/components/LinkButton';
import { t } from 'i18next';
import { addLocalLog } from '@ente/shared/logging';
import { Input } from '@mui/material';
import SingleInputForm, {
    SingleInputFormProps,
} from '@ente/shared/components/SingleInputForm';
import { APPS } from '@ente/shared/apps/constants';

interface LoginProps {
    signUp: () => void;
    appName: APPS;
}

export default function Login(props: LoginProps) {
    const router = useRouter();

    const loginUser: SingleInputFormProps['callback'] = async (
        email,
        setFieldError
    ) => {
        try {
            setData(LS_KEYS.USER, { email });
            const srpAttributes = await getSRPAttributes(email);
            addLocalLog(
                () => ` srpAttributes: ${JSON.stringify(srpAttributes)}`
            );
            if (!srpAttributes || srpAttributes.isEmailMFAEnabled) {
                await sendOtt(props.appName, email);
                router.push(PAGES.VERIFY);
            } else {
                setData(LS_KEYS.SRP_ATTRIBUTES, srpAttributes);
                router.push(PAGES.CREDENTIALS);
            }
        } catch (e) {
            if (e instanceof Error) {
                setFieldError(`${t('UNKNOWN_ERROR')} (reason:${e.message})`);
            } else {
                setFieldError(
                    `${t('UNKNOWN_ERROR')} (reason:${JSON.stringify(e)})`
                );
            }
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
                hiddenPostInput={
                    <Input sx={{ display: 'none' }} type="password" value="" />
                }
            />

            <FormPaperFooter>
                <LinkButton onClick={props.signUp}>
                    {t('NO_ACCOUNT')}
                </LinkButton>
            </FormPaperFooter>
        </>
    );
}
