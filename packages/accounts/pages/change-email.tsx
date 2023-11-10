import { VerticallyCentered } from '@ente/shared/components/Container';
import React, { useEffect } from 'react';
import { t } from 'i18next';

import ChangeEmailForm from '@ente/accounts/components/ChangeEmail';
import { PAGES } from '@ente/accounts/constants/pages';
import { getData, LS_KEYS } from '@ente/shared/storage/localStorage';
import FormPaper from '@ente/shared/components/Form/FormPaper';
import FormPaperTitle from '@ente/shared/components/Form/FormPaper/Title';
import { PageProps } from '@ente/shared/apps/types';

function ChangeEmailPage({ router, appName, appContext }: PageProps) {
    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (!user?.token) {
            router.push(PAGES.ROOT);
        }
    }, []);

    return (
        <VerticallyCentered>
            <FormPaper>
                <FormPaperTitle>{t('CHANGE_EMAIL')}</FormPaperTitle>
                <ChangeEmailForm
                    router={router}
                    appName={appName}
                    appContext={appContext}
                />
            </FormPaper>
        </VerticallyCentered>
    );
}

export default ChangeEmailPage;
