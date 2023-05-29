import React, { useState, useEffect, useContext } from 'react';
import { useRouter } from 'next/router';
import { AppContext } from 'pages/_app';
import EnteSpinner from 'components/EnteSpinner';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import SignUp from 'components/SignUp';
import { PAGES } from 'constants/pages';
import FormPaper from 'components/Form/FormPaper';
import { VerticallyCentered } from 'components/Container';

export default function SignUpPage() {
    const router = useRouter();
    const appContext = useContext(AppContext);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        router.prefetch(PAGES.VERIFY);
        router.prefetch(PAGES.LOGIN);
        const user = getData(LS_KEYS.USER);
        if (user?.email) {
            router.push(PAGES.VERIFY);
        }
        setLoading(false);
        appContext.showNavBar(true);
    }, []);

    const login = () => {
        router.push(PAGES.LOGIN);
    };

    return (
        <VerticallyCentered>
            {loading ? (
                <EnteSpinner />
            ) : (
                <FormPaper>
                    <SignUp login={login} />
                </FormPaper>
            )}
        </VerticallyCentered>
    );
}
