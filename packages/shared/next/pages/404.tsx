import { VerticallyCentered } from '@ente/shared/components/Container';
import React, { useEffect, useState } from 'react';
import { t } from 'i18next';

import EnteSpinner from '@ente/shared/components/EnteSpinner';
import { PageProps } from '@ente/shared/apps/types';

export default function NotFound({ appContext }: PageProps) {
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
