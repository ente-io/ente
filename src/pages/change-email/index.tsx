import VerticallyCentered, { CenteredFlex } from 'components/Container';
import LogoImg from 'components/LogoImg';
import React, { useEffect } from 'react';
import constants from 'utils/strings/constants';
import router from 'next/router';
import ChangeEmailForm from 'components/ChangeEmail';
import { PAGES } from 'constants/pages';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import FormPaper from 'components/Form/FormPaper';

function ChangeEmailPage() {
    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (!user?.token) {
            router.push(PAGES.ROOT);
        }
    }, []);

    return (
        <VerticallyCentered>
            <FormPaper>
                <CenteredFlex mb={8}>
                    <LogoImg src="/icon.svg" />
                    {constants.CHANGE_EMAIL}
                </CenteredFlex>
                <ChangeEmailForm />
            </FormPaper>
        </VerticallyCentered>
    );
}

export default ChangeEmailPage;
