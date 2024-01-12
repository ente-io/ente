import EnteSpinner from '@ente/shared/components/EnteSpinner';
import { VerticallyCentered } from '@ente/shared/components/Container';
import { setData, LS_KEYS } from '@ente/shared/storage/localStorage';
import { useRouter } from 'next/router';
import { ACCOUNTS_PAGES } from '@ente/shared/constants/pages';
import { useEffect } from 'react';
import { logError } from '@ente/shared/sentry';

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

    useEffect(() => {
        retrieveAccountData();
    }, []);

    return (
        <VerticallyCentered>
            <EnteSpinner />
        </VerticallyCentered>
    );
};

export default AccountHandoff;
