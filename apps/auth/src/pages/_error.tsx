import ErrorPage from '@ente/shared/next/pages/_error';
import { useRouter } from 'next/router';
import { AppContext } from 'pages/_app';
import { useContext } from 'react';
import { APPS } from '@ente/shared/apps/constants';

export default function Error() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return (
        <ErrorPage
            appContext={appContext}
            router={router}
            appName={APPS.AUTH}
        />
    );
}
