import ChangePasswordPage from '@ente/accounts/pages/change-password';
import { useRouter } from 'next/router';
import { AppContext } from 'pages/_app';
import { useContext } from 'react';
import { APPS } from '@ente/shared/apps/constants';

export default function ChangePassword() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return (
        <ChangePasswordPage
            appContext={appContext}
            router={router}
            appName={APPS.AUTH}
        />
    );
}
