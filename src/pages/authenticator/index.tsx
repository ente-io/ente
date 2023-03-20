import React, { useEffect, useState } from 'react';
import OTPDisplay from 'components/Authenicator/OTPDisplay';
import { getAuthCodes } from 'services/authenticator/authenticatorService';
import { Button } from '@mui/material';
import { CustomError } from 'utils/error';

const OTPPage = () => {
    const [codes, setCodes] = useState([]);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        const fetchCodes = async () => {
            try {
                getAuthCodes()
                    .then((res) => {
                        setCodes(res);
                    })
                    .catch((err) => {
                        if (err.message === CustomError.KEY_MISSING) {
                            window.location.href = '/';
                            return;
                        }

                        console.error('something wrong here', err);
                    });
            } catch (error) {
                console.error('something wrong where asdas');
                console.error(error);
            }
        };
        fetchCodes();
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

    const DownloadApp = () => {
        return (
            <div
                style={{
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                }}>
                <p>Download our mobile app to add &amp; manage your secrets.</p>
                <a href="https://github.com/ente-io/auth#-download" download>
                    <Button
                        style={{
                            backgroundColor: 'green',
                            padding: '12px 18px',
                            color: 'white',
                        }}>
                        Download
                    </Button>
                </a>
            </div>
        );
    };

    return (
        <div
            style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'flex-start',
            }}>
            <h2>ente Authenticator</h2>
            <input
                type="text"
                placeholder="Search"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
            />

            <div style={{ marginBottom: '1rem' }} />
            {filteredCodes.length === 0 ? (
                <div
                    style={{
                        alignItems: 'center',
                        display: 'flex',
                        textAlign: 'center',
                        marginTop: '32px',
                    }}>
                    {searchTerm.length !== 0 ? (
                        <p>No results found.</p>
                    ) : (
                        <div />
                    )}
                </div>
            ) : (
                filteredCodes.map((code) => (
                    <OTPDisplay codeInfo={code} key={code.id} />
                ))
            )}
            <div style={{ marginBottom: '2rem' }} />
            <DownloadApp />
            <div style={{ marginBottom: '4rem' }} />
        </div>
    );
};

export default OTPPage;
