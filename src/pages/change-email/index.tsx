import VerticallyCentered from 'components/Container';
import React, { useEffect } from 'react';
import { useTranslation } from 'react-i18next';

import router from 'next/router';
import ChangeEmailForm from 'components/ChangeEmail';
import { PAGES } from 'constants/pages';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import FormPaper from 'components/Form/FormPaper';
import FormPaperTitle from 'components/Form/FormPaper/Title';

function ChangeEmailPage() {
    const { t } = useTranslation();
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
                <ChangeEmailForm />
            </FormPaper>
        </VerticallyCentered>
    );
}

export default ChangeEmailPage;
