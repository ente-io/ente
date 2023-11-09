import SignupPage from '@ente/accounts/pages/signup';
import { useRouter } from 'next/router';
import { AppContext } from 'pages/_app';
import { useContext } from 'react';
import { APPS } from '@ente/shared/apps/constants';

export default function Sigup() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return (
        <SignupPage
            appContext={appContext}
            router={router}
            appName={APPS.AUTH}
        />
    );
}
