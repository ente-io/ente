import { VerticallyCentered } from 'components/Container';
import React, { useContext, useEffect, useState } from 'react';
import { t } from 'i18next';

import { AppContext } from './_app';
import EnteSpinner from '@ente/shared/components/EnteSpinner';

export default function NotFound() {
    const appContext = useContext(AppContext);
    const [loading, setLoading] = useState(true);
    useEffect(() => {
        appContext.showNavBar(true);
        setLoading(false);
    }, []);
    return (
        <VerticallyCentered>
            {loading ? <EnteSpinner /> : t('NOT_FOUND')}
        </VerticallyCentered>
    );
}
