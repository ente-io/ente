import React, { useState, useEffect, useContext } from 'react';
import { useRouter } from 'next/router';
import EnteSpinner from 'components/EnteSpinner';
import { AppContext } from 'pages/_app';
import Login from 'components/Login';
import { VerticallyCentered } from 'components/Container';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { PAGES } from 'constants/pages';
import FormPaper from 'components/Form/FormPaper';

export default function Home() {
    const router = useRouter();
    const appContext = useContext(AppContext);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        router.prefetch(PAGES.VERIFY);
        router.prefetch(PAGES.SIGNUP);
        const user = getData(LS_KEYS.USER);
        if (user?.email) {
            router.push(PAGES.VERIFY);
        }
        setLoading(false);
        appContext.showNavBar(true);
    }, []);

    const register = () => {
        router.push(PAGES.SIGNUP);
    };

    return loading ? (
        <VerticallyCentered>
            <EnteSpinner />
        </VerticallyCentered>
    ) : (
        <VerticallyCentered>
            <FormPaper>
                <Login signUp={register} />
            </FormPaper>
        </VerticallyCentered>
    );
}
