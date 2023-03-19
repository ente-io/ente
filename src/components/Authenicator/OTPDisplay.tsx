import React, { useState, useEffect } from 'react';
import { TOTP, HOTP } from 'otpauth';
import TimerProgress from './TimerProgress';

const TOTPDisplay = ({ issuer, account, code, nextCode }) => {
    return (
        <div
            style={{
                padding: '4px 16px',
                display: 'flex',
                alignItems: 'flex-start',
                minWidth: '320px',
                borderRadius: '4px',
                backgroundColor: 'rgba(40, 40, 40, 0.6)',
                justifyContent: 'space-between',
            }}>
            <div
                style={{
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'flex-start',
                    minWidth: '200px',
                }}>
                <p
                    style={{
                        fontWeight: 'bold',
                        marginBottom: '0px',
                        fontSize: '14px',
                        textAlign: 'left',
                    }}>
                    {issuer}
                </p>
                <p
                    style={{
                        marginBottom: '8px',
                        textAlign: 'left',
                        fontSize: '12px',
                    }}>
                    {account}
                </p>
                <p
                    style={{
                        fontSize: '24px',
                        fontWeight: 'bold',
                        textAlign: 'left',
                    }}>
                    {code}
                </p>
            </div>
            <div style={{ flex: 1 }} />
            <div
                style={{
                    display: 'flex',
                    flexDirection: 'column',
                    marginTop: '32px',
                    alignItems: 'flex-end',
                    minWidth: '120px',
                    textAlign: 'right',
                }}>
                <p
                    style={{
                        fontWeight: 'bold',
                        marginBottom: '0px',
                        fontSize: '10px',
                        marginTop: 'auto',
                        textAlign: 'right',
                    }}>
                    next
                </p>
                <p
                    style={{
                        fontSize: '14px',
                        fontWeight: 'bold',
                        marginBottom: '0px',
                        marginTop: 'auto',
                        textAlign: 'right',
                    }}>
                    {nextCode}
                </p>
            </div>
        </div>
    );
};

const OTPDisplay = ({
    secret,
    type,
    algorithm,
    timePeriod,
    issuer,
    account,
}) => {
    const [code, setCode] = useState('');
    const [nextcode, setNextCode] = useState('');

    const generateCodes = () => {
        const currentTime = new Date().getTime();
        if (type.toLowerCase() === 'totp') {
            const totp = new TOTP({
                secret,
                algorithm,
                period: timePeriod ?? 30,
            });
            setCode(totp.generate());
            setNextCode(
                totp.generate({ timestamp: currentTime + timePeriod * 1000 })
            );
        } else if (type.toLowerCase() === 'hotp') {
            const hotp = new HOTP({ secret, counter: 0, algorithm });
            setCode(hotp.generate());
            setNextCode(hotp.generate({ counter: 1 }));
        }
    };

    useEffect(() => {
        let intervalId;
        // compare case insensitive type

        if (type.toLowerCase() === 'totp') {
            intervalId = setInterval(() => {
                generateCodes();
            }, 1000);
        } else if (type.toLowerCase() === 'hotp') {
            intervalId = setInterval(() => {
                generateCodes();
            }, 1000);
        }

        return () => clearInterval(intervalId);
    }, [secret, type, algorithm, timePeriod]);

    return (
        <div style={{ padding: '8px' }}>
            <TimerProgress period={timePeriod} />
            <TOTPDisplay
                issuer={issuer}
                account={account}
                code={code}
                nextCode={nextcode}
            />
        </div>
    );
};

export default OTPDisplay;
