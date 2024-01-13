import { VerticallyCentered } from '@ente/shared/components/Container';
import EnteSpinner from '@ente/shared/components/EnteSpinner';
import { ACCOUNTS_PAGES } from '@ente/shared/constants/pages';
import HTTPService from '@ente/shared/network/HTTPService';
import { logError } from '@ente/shared/sentry';
import { LS_KEYS, setData } from '@ente/shared/storage/localStorage';
import { useRouter } from 'next/router';
import { useEffect } from 'react';

const AccountHandoff = () => {
    const router = useRouter();

    const retrieveAccountData = () => {
        try {
            // get the data from the fragment
            const fragment = window.location.hash;

            const stringified = window.atob(fragment);

            const deserialized = JSON.parse(stringified);

            setData(LS_KEYS.USER, deserialized);

            router.push(ACCOUNTS_PAGES.PASSKEYS);
        } catch (e) {
            logError(e, 'Failed to deserialize and set passed user data');
            router.push(ACCOUNTS_PAGES.LOGIN);
        }
    };

    const getClientPackageName = () => {
        const urlParams = new URLSearchParams(window.location.search);
        const pkg = urlParams.get('package');
        if (!pkg) return;
        setData(LS_KEYS.CLIENT_PACKAGE, { name: pkg });
        HTTPService.setHeaders({
            'X-Client-Package': pkg,
        });
    };

    useEffect(() => {
        getClientPackageName();
        retrieveAccountData();
    }, []);

    return (
        <VerticallyCentered>
            <EnteSpinner />
        </VerticallyCentered>
    );
};

export default AccountHandoff;
