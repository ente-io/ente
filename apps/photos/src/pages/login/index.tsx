import LoginPage from '@ente/accounts/pages/login';
import { useRouter } from 'next/router';
import { AppContext } from 'pages/_app';
import { useContext } from 'react';

export default function Login() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return <LoginPage appContext={appContext} router={router} />;
}
