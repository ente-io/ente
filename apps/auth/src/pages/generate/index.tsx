import GeneratePage from '@ente/accounts/pages/generate';
import { useRouter } from 'next/router';
import { AppContext } from 'pages/_app';
import { useContext } from 'react';
import { APPS } from '@ente/shared/apps/constants';

export default function Generate() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return (
        <GeneratePage
            appContext={appContext}
            router={router}
            appName={APPS.PHOTOS}
        />
    );
}
