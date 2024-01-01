import CredentialPage from '@ente/accounts/pages/credentials';
import { useRouter } from 'next/router';
import { AppContext } from '../_app';
import { useContext } from 'react';
import { APPS } from '@ente/shared/apps/constants';

export default function Credential() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return (
        <CredentialPage
            appContext={appContext}
            router={router}
            appName={APPS.ACCOUNTS}
        />
    );
}
