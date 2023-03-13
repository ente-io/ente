import VerticallyCentered from 'components/Container';
import React, { useContext, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';

import { AppContext } from './_app';

export default function NotFound() {
    const { t } = useTranslation();

    const appContext = useContext(AppContext);
    const [loading, setLoading] = useState(true);
    useEffect(() => {
        appContext.showNavBar(true);
        setLoading(false);
    }, []);
    return (
        <VerticallyCentered>
            {loading ? (
                <span className="sr-only">Loading...</span>
            ) : (
                t('NOT_FOUND')
            )}
        </VerticallyCentered>
    );
}
