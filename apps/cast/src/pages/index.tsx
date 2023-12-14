import { useEffect, useState } from 'react';
import _sodium from 'libsodium-wrappers';
import { getKexValue, setKexValue } from '@ente/shared/network/kexService';
import {
    boxSealOpen,
    fromB64,
    toB64,
} from '@ente/shared/crypto/internal/libsodium';
import { useRouter } from 'next/router';
import { SESSION_KEYS, setKey } from '@ente/shared/storage/sessionStorage';
import TimerBar from 'components/TimerBar';
import LargeType from 'components/LargeType';
import { useCastReceiver } from '@ente/shared/hooks/useCastReceiver';

// Function to generate cryptographically secure digits
const generateSecureData = (length: number): Uint8Array => {
    const array = new Uint8Array(length);
    window.crypto.getRandomValues(array);
    // Modulo operation to ensure each byte is a single digit
    for (let i = 0; i < length; i++) {
        array[i] = array[i] % 10;
    }
    return array;
};

const convertDataToDecimalString = (data: Uint8Array): string => {
    let decimalString = '';
    for (let i = 0; i < data.length; i++) {
        decimalString += data[i].toString(); // No need to pad, as each value is a single digit
    }
    return decimalString;
};

export default function PairingMode() {
    const [digits, setDigits] = useState<string[]>([]);

    const [publicKeyB64, setPublicKeyB64] = useState('');

    const [codeGeneratedAt, setCodeGeneratedAt] = useState<Date | null>(null);

    const [borderWidthPercentage, setBorderWidthPercentage] = useState(100);

    const { cast } = useCastReceiver();

    useEffect(() => {
        init();
        const interval = setInterval(() => {
            init();
        }, 45 * 1000); // the kex API deletes keys every 60s, so we'll regenerate stuff prematurely

        return () => {
            clearInterval(interval);
        };
    }, []);

    useEffect(() => {
        if (!cast) return;
        cast.framework.CastReceiverContext.getInstance().addCustomMessageListener(
            'urn:x-cast:pair-request',
            messageReceiveHandler
        );
    }, [cast]);

    const messageReceiveHandler = (message: {
        type: string;
        senderId: string;
        data: any;
    }) => {
        if (message.type === 'urn:x-cast:pair-request') {
            // send the 6 digit code to the sender

            cast.framework.CastReceiverContext.getInstance().sendCustomMessage(
                'urn:x-cast:pair-response',
                message.senderId,
                {
                    code: digits.join(''),
                }
            );
        }
    };

    const init = async () => {
        const data = generateSecureData(6);
        setDigits(convertDataToDecimalString(data).split(''));

        const keypair = await generateKeyPair();
        setPublicKeyB64(await toB64(keypair.publicKey));
        setPrivateKeyB64(await toB64(keypair.privateKey));
    };

    const [privateKeyB64, setPrivateKeyB64] = useState('');

    const generateKeyPair = async () => {
        await _sodium.ready;

        const keypair = _sodium.crypto_box_keypair();

        return keypair;
    };

    const pollForCastData = async () => {
        // see if we were acknowledged on the client.
        // the client will send us the encrypted payload using our public key that we advertised.
        // then, we can decrypt this and store all the necessary info locally so we can play the collection slideshow.
        let devicePayload = '';
        try {
            devicePayload = await getKexValue(`${digits.join('')}_payload`);
        } catch (e) {
            return;
        }

        const decryptedPayload = await boxSealOpen(
            devicePayload,
            publicKeyB64,
            privateKeyB64
        );

        const nonB64 = await fromB64(decryptedPayload);

        const decryptedPayloadObj = JSON.parse(
            new TextDecoder().decode(nonB64)
        );

        return decryptedPayloadObj;
    };

    const storePayloadLocally = (payloadObj: Object) => {
        // iterate through all the keys in the payload object and set them in localStorage.
        // if the key is "encryptionKey", store it in session storage instead.
        for (const key in payloadObj) {
            if (key === 'sessionKey') {
                setKey(SESSION_KEYS.ENCRYPTION_KEY, payloadObj[key]);
            } else {
                window.localStorage.setItem(key, payloadObj[key]);
            }
        }
    };

    const advertisePublicKey = async (publicKeyB64: string) => {
        // hey client, we exist!
        try {
            await setKexValue(`${digits.join('')}_pubkey`, publicKeyB64);
        } catch (e) {
            return;
        }

        setCodeGeneratedAt(new Date());
    };

    const router = useRouter();

    useEffect(() => {
        if (digits.length < 1 || !publicKeyB64 || !privateKeyB64) return;

        const interval = setInterval(async () => {
            const data = await pollForCastData();

            if (!data) return;

            storePayloadLocally(data);

            router.push('/slideshow');
        }, 1000);

        return () => {
            clearInterval(interval);
        };
    }, [digits, publicKeyB64, privateKeyB64]);

    useEffect(() => {
        if (!publicKeyB64) return;

        advertisePublicKey(publicKeyB64);
    }, [publicKeyB64]);

    useEffect(() => {
        if (!codeGeneratedAt) return;

        // compute border width based on time left until next code regenerates
        const interval = setInterval(() => {
            const now = new Date();
            const timeLeft =
                codeGeneratedAt.getTime() + 45 * 1000 - now.getTime();

            if (timeLeft > 0) {
                const percentage = (timeLeft / (45 * 1000)) * 100;

                setBorderWidthPercentage(percentage);
            }
        }, 250);

        return () => {
            clearInterval(interval);
        };
    }, [codeGeneratedAt]);

    return (
        <>
            <div
                style={{
                    height: '100%',
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center',
                }}>
                <div
                    style={{
                        textAlign: 'center',
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                    }}>
                    <img width={150} src="/images/ente.svg" />
                    <h1
                        style={{
                            fontWeight: 'normal',
                        }}>
                        Enter this code on <b>ente</b> to pair this TV
                    </h1>
                    <div
                        style={{
                            borderRadius: '10px',
                            overflow: 'hidden',
                        }}>
                        <LargeType chars={digits} />
                        <TimerBar percentage={borderWidthPercentage} />
                    </div>
                    <p
                        style={{
                            fontSize: '1.2rem',
                        }}>
                        Visit{' '}
                        <a
                            style={{
                                textDecoration: 'none',
                                color: '#87CEFA',
                                fontWeight: 'bold',
                            }}
                            href="https://ente.io/cast"
                            target="_blank">
                            ente.io/cast
                        </a>{' '}
                        for help
                    </p>
                </div>
            </div>
        </>
    );
}
