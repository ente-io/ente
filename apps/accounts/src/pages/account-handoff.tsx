import { VerticallyCentered } from '@ente/shared/components/Container';
import EnteSpinner from '@ente/shared/components/EnteSpinner';
import { ACCOUNTS_PAGES } from '@ente/shared/constants/pages';
import HTTPService from '@ente/shared/network/HTTPService';
import { logError } from '@ente/shared/sentry';
import { LS_KEYS, getData, setData } from '@ente/shared/storage/localStorage';
import { useRouter } from 'next/router';
import { useEffect } from 'react';

const AccountHandoff = () => {
    const router = useRouter();

    const retrieveAccountData = () => {
        try {
            extractAccountsToken();

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

    const extractAccountsToken = () => {
        const urlParams = new URLSearchParams(window.location.search);
        const token = urlParams.get('token');
        if (!token) {
            throw new Error('token not found');
        }

        const user = getData(LS_KEYS.USER) || {};
        user.token = token;

        setData(LS_KEYS.USER, user);
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
