import React, { useEffect, useState } from 'react';
import OTPDisplay from 'components/Authenicator/OTPDisplay';
const random = [
    {
        issuer: 'Google',
        account: 'example@gmail.com',
        secret: '6GJ2E2RQKJ36BY6A',
        type: 'TOTP',
        algorithm: 'SHA1',
        period: 30,
    },
    {
        issuer: 'Facebook',
        account: 'example@gmail.com',
        secret: 'RVZJ7N6KJKJGQ2VX',
        type: 'TOTP',
        algorithm: 'SHA256',
        period: 60,
    },
    {
        issuer: 'Twitter',
        account: 'example@gmail.com',
        secret: 'ZPUE6KJ3WGZ3HPKJ',
        type: 'TOTP',
        algorithm: 'SHA256',
        period: 60,
    },
    {
        issuer: 'GitHub',
        account: 'example@gmail.com',
        secret: 'AG6U5KJYHPRRNRZI',
        type: 'TOTP',
        algorithm: 'SHA1',
        period: 30,
    },
    {
        issuer: 'Amazon',
        account: 'example@gmail.com',
        secret: 'Q2FR2KJVKJFFKMWZ',
        type: 'TOTP',
        algorithm: 'SHA256',
        period: 60,
    },
    {
        issuer: 'LinkedIn',
        account: 'example@gmail.com',
        secret: 'SWRG4KJ4J3LNDW2Z',
        type: 'TOTP',
        algorithm: 'SHA256',
        period: 60,
    },
    {
        issuer: 'Dropbox',
        account: 'example@gmail.com',
        secret: 'G5U6OKJU3JRM72ZK',
        type: 'TOTP',
        algorithm: 'SHA1',
        period: 30,
    },
];

const OTPPage = () => {
    const [secrets, setSecrets] = useState([]);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        const fetchSecrets = async () => {
            try {
                setSecrets(random);
            } catch (error) {
                console.error(error);
            }
        };
        fetchSecrets();
    }, []);

    const filteredSecrets = secrets.filter(
        (secret) =>
            secret.issuer.toLowerCase().includes(searchTerm.toLowerCase()) ||
            secret.account.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        // center the page
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
            {filteredSecrets.length === 0 ? (
                <div
                    style={{
                        alignItems: 'center',
                        display: 'flex',
                        textAlign: 'center',
                        marginTop: '32px',
                    }}>
                    <p>No results found. </p>
                    {/* <p style={{ marginLeft: '4px' }}>Add a new secret to get started.</p> 
                    <p>Download ente auth mobile app to manage your secrets</p> */}
                </div>
            ) : (
                filteredSecrets.map((secret) => (
                    <OTPDisplay
                        key={secret.secret}
                        secret={secret.secret}
                        type={secret.type}
                        algorithm={secret.algorithm}
                        timePeriod={secret.period}
                        issuer={secret.issuer}
                        account={secret.account}
                    />
                ))
            )}
        </div>
    );
};

export default OTPPage;
