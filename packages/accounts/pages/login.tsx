import { useState, useEffect } from 'react';
// import { AppContext } from 'pages/_app';
// import Login from 'components/Login';
// import { VerticallyCentered } from '@ente/ui/components/Container';
// import { getData, LS_KEYS } from 'utils/storage/localStorage';
// import { PAGES } from 'constants/pages';
// import FormPaper from 'components/Form/FormPaper';

export default function LoginPage() {
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        setLoading(false);
    }, []);

    return loading ? <div>abc</div> : <div>xyz</div>;
}
