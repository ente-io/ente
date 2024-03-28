import { Container } from 'components/Container';
import EnteSpinner from 'components/EnteSpinner';
import { ENTE_WEBSITE_URL } from 'constants/common';
import React, { useEffect, useState } from 'react';
import { parseAndHandleRequest } from 'services/billingService';
import { CUSTOM_ERROR } from 'utils/error';
import constants from 'utils/strings/constants';

export default function Home() {
    const [errorMessageView, setErrorMessageView] = useState(false);
    const [loading, setLoading] = useState(false);
    useEffect(() => {
        async function main() {
            try {
                setLoading(true);
                await parseAndHandleRequest();
            } catch (e: any) {
                if (
                    e.message === CUSTOM_ERROR.DIRECT_OPEN_WITH_NO_QUERY_PARAMS
                ) {
                    window.location.href = ENTE_WEBSITE_URL;
                } else {
                    setErrorMessageView(true);
                }
            }
        }
        main();
    }, []);

    return (
        <Container>
            {errorMessageView ? (
                <div>{constants.SOMETHING_WENT_WRONG}</div>
            ) : (
                loading && <EnteSpinner animation="border" />
            )}
        </Container>
    );
}
