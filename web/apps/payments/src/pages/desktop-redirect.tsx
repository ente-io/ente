import { Container } from 'components/Container';
import EnteSpinner from 'components/EnteSpinner';
import { DESKTOP_REDIRECT_URL } from 'constants/common';
import { useRouter } from 'next/dist/client/router';
import React, { useEffect, useState } from 'react';

export default function DesktopRedirect() {
    useEffect(() => {
        const currentURL = new URL(window.location.href);
        const desktopRedirectURL = new URL(DESKTOP_REDIRECT_URL);
        desktopRedirectURL.search = currentURL.search;
        window.location.href = desktopRedirectURL.href;
    }, []);

    return (
        <Container>
            <EnteSpinner animation="border" />
        </Container>
    );
}
