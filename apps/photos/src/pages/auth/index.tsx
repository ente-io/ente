import React, { useContext, useEffect, useState } from 'react';
import OTPDisplay from 'components/Authenicator/OTPDisplay';
import { getAuthCodes } from 'services/authenticator/authenticatorService';
import { CustomError } from 'utils/error';
import { PAGES } from 'constants/pages';
import { useRouter } from 'next/router';
import { AuthFooter } from 'components/Authenicator/AuthFooter';
import { AppContext } from 'pages/_app';
import { TextField } from '@mui/material';
import AuthNavbar from 'components/pages/auth/Navbar';
import { t } from 'i18next';
import EnteSpinner from 'components/EnteSpinner';
import { VerticallyCentered } from 'components/Container';

const AuthenticatorCodesPage = () => {
    const appContext = useContext(AppContext);
    const router = useRouter();
    const [codes, setCodes] = useState([]);
    const [hasFetched, setHasFetched] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        const fetchCodes = async () => {
            try {
                const res = await getAuthCodes();
                setCodes(res);
            } catch (err) {
                if (err.message === CustomError.KEY_MISSING) {
                    appContext.setRedirectURL(PAGES.AUTH);
                    router.push(PAGES.ROOT);
                } else {
                    // do not log errors
                }
            }
            setHasFetched(true);
        };
        fetchCodes();
        appContext.showNavBar(false);
    }, []);

    const filteredCodes = codes.filter(
        (secret) =>
            (secret.issuer ?? '')
                .toLowerCase()
                .includes(searchTerm.toLowerCase()) ||
            (secret.account ?? '')
                .toLowerCase()
                .includes(searchTerm.toLowerCase())
    );

    if (!hasFetched) {
        return (
            <>
                <VerticallyCentered>
                    <EnteSpinner></EnteSpinner>
                </VerticallyCentered>
                ;
            </>
        );
    }

    return (
        <>
            <AuthNavbar />
            <div
                style={{
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'flex-start',
                }}>
                <div style={{ marginBottom: '1rem' }} />
                {filteredCodes.length === 0 && searchTerm.length === 0 ? (
                    <></>
                ) : (
                    <TextField
                        id="search"
                        name="search"
                        label={t('SEARCH')}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        variant="filled"
                        style={{ width: '350px' }}
                        value={searchTerm}
                        autoFocus
                    />
                )}

                <div style={{ marginBottom: '1rem' }} />
                <div
                    style={{
                        display: 'flex',
                        flexDirection: 'row',
                        flexWrap: 'wrap',
                        justifyContent: 'center',
                    }}>
                    {filteredCodes.length === 0 ? (
                        <div
                            style={{
                                alignItems: 'center',
                                display: 'flex',
                                textAlign: 'center',
                                marginTop: '32px',
                            }}>
                            {searchTerm.length !== 0 ? (
                                <p>{t('NO_RESULTS')}</p>
                            ) : (
                                <div />
                            )}
                        </div>
                    ) : (
                        filteredCodes.map((code) => (
                            <OTPDisplay
                                codeInfo={code}
                                key={code.id}
                                style={{
                                    width: '100%',
                                    maxWidth: '400px',
                                    margin: '0.5rem',
                                }}
                            />
                        ))
                    )}
                </div>
                <div style={{ marginBottom: '2rem' }} />
                <AuthFooter />
                <div style={{ marginBottom: '4rem' }} />
            </div>
            <style jsx>{`
                @media (min-width: 800px) {
                    .row {
                        display: flex;
                        flex-wrap: wrap;
                        justify-content: center;
                    }
                    .col {
                        flex: 0 0 50%;
                        max-width: 50%;
                    }
                }
            `}</style>
        </>
    );
};

export default AuthenticatorCodesPage;
