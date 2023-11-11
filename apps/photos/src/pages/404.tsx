import NotFoundPage from '@ente/shared/next/pages/404';
import { useRouter } from 'next/router';
import { AppContext } from 'pages/_app';
import { useContext } from 'react';
import { APPS } from '@ente/shared/apps/constants';

export default function NotFound() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return (
        <NotFoundPage
            appContext={appContext}
            router={router}
            appName={APPS.AUTH}
        />
    );
}
