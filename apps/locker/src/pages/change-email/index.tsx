import ChangeEmailPage from '@ente/accounts/pages/change-email';
import { useRouter } from 'next/router';
import { AppContext } from 'pages/_app';
import { useContext } from 'react';
import { APPS } from '@ente/shared/apps/constants';

export default function ChangeEmail() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return (
        <ChangeEmailPage
            appContext={appContext}
            router={router}
            appName={APPS.PHOTOS}
        />
    );
}
