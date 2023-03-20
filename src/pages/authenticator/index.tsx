import React, { useEffect, useState } from 'react';
import OTPDisplay from 'components/Authenicator/OTPDisplay';
import { getAuthCodes } from 'services/authenticator/authenticatorService';

const OTPPage = () => {
    const [codes, setCodes] = useState([]);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        const fetchCodes = async () => {
            try {
                getAuthCodes().then((res) => {
                    setCodes(res);
                });
            } catch (error) {
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
            {filteredCodes.length === 0 ? (
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
                filteredCodes.map((code) => (
                    <OTPDisplay codeInfo={code} key={code.id} />
                ))
            )}
        </div>
    );
};

export default OTPPage;
