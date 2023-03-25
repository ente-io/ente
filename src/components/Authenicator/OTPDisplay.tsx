import React, { useState, useEffect } from 'react';
import { TOTP, HOTP } from 'otpauth';
import { Code } from 'types/authenticator/code';
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

function BadCodeInfo({ codeInfo, codeErr }) {
    const [showRawData, setShowRawData] = useState(false);

    return (
        <div className="code-info">
            <div>{codeInfo.title}</div>
            <div>{codeErr}</div>
            <div>
                {showRawData ? (
                    <div onClick={() => setShowRawData(false)}>
                        {codeInfo.rawData ?? 'no raw data'}
                    </div>
                ) : (
                    <div onClick={() => setShowRawData(true)}>Show rawData</div>
                )}
            </div>
        </div>
    );
}

interface OTPDisplayProps {
    codeInfo: Code;
}

const OTPDisplay = (props: OTPDisplayProps) => {
    const { codeInfo } = props;
    const [code, setCode] = useState('');
    const [nextCode, setNextCode] = useState('');
    const [codeErr, setCodeErr] = useState('');
    const generateCodeInterval = 1000;

    const generateCodes = () => {
        try {
            const currentTime = new Date().getTime();
            if (codeInfo.type.toLowerCase() === 'totp') {
                const totp = new TOTP({
                    secret: codeInfo.secret,
                    algorithm: codeInfo.algorithm ?? Code.defaultAlgo,
                    period: codeInfo.period ?? Code.defaultPeriod,
                    digits: codeInfo.digits ?? Code.defaultDigits,
                });
                setCode(totp.generate());
                setNextCode(
                    totp.generate({
                        timestamp: currentTime + codeInfo.period * 1000,
                    })
                );
            } else if (codeInfo.type.toLowerCase() === 'hotp') {
                const hotp = new HOTP({
                    secret: codeInfo.secret,
                    counter: 0,
                    algorithm: codeInfo.algorithm,
                });
                setCode(hotp.generate());
                setNextCode(hotp.generate({ counter: 1 }));
            }
        } catch (err) {
            setCodeErr(err.message);
        }
    };

    useEffect(() => {
        generateCodes();
        const codeType = codeInfo.type;
        const intervalId =
            codeType.toLowerCase() === 'totp' ||
            codeType.toLowerCase() === 'hotp'
                ? setInterval(() => {
                      generateCodes();
                  }, generateCodeInterval)
                : null;

        return () => {
            if (intervalId) clearInterval(intervalId);
        };
    }, [codeInfo]);

    return (
        <div style={{ padding: '8px' }}>
            <TimerProgress period={codeInfo.period ?? Code.defaultPeriod} />
            {codeErr === '' ? (
                <TOTPDisplay
                    issuer={codeInfo.issuer}
                    account={codeInfo.account}
                    code={code}
                    nextCode={nextCode}
                />
            ) : (
                <BadCodeInfo codeInfo={codeInfo} codeErr={codeErr} />
            )}
        </div>
    );
};

export default OTPDisplay;
