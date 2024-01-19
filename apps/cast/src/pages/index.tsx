import { useEffect, useState } from 'react';
import _sodium from 'libsodium-wrappers';
import castGateway from '@ente/shared/network/cast';
import {
    boxSealOpen,
    fromB64,
    toB64,
} from '@ente/shared/crypto/internal/libsodium';
import { useRouter } from 'next/router';
import TimerBar from 'components/TimerBar';
import LargeType from 'components/LargeType';
import { useCastReceiver } from '@ente/shared/hooks/useCastReceiver';
import EnteSpinner from '@ente/shared/components/EnteSpinner';

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

const REFRESH_INTERVAL = 3600 * 1000;

export default function PairingMode() {
    const [digits, setDigits] = useState<string[]>([]);

    const [publicKeyB64, setPublicKeyB64] = useState('');

    const [codeGeneratedAt, setCodeGeneratedAt] = useState<Date | null>(null);

    const [borderWidthPercentage, setBorderWidthPercentage] = useState(100);

    const [codePending, setCodePending] = useState(true);

    const { cast } = useCastReceiver();

    useEffect(() => {
        init();
        const interval = setInterval(() => {
            setCodePending(true);
            init();
        }, REFRESH_INTERVAL); // the kex API deletes keys every 60s, so we'll regenerate stuff prematurely

        return () => {
            clearInterval(interval);
        };
    }, []);

    useEffect(() => {
        if (!cast) return;
        const context = cast.framework.CastReceiverContext.getInstance();

        const options = new cast.framework.CastReceiverOptions();
        options.customNamespaces = Object.assign({});
        options.customNamespaces['urn:x-cast:pair-request'] =
            cast.framework.system.MessageType.JSON;

        options.disableIdleTimeout = true;

        context.addCustomMessageListener(
            'urn:x-cast:pair-request',
            messageReceiveHandler
        );

        context.start(options);

        return () => {
            context.stop(options);
        };
    }, [cast]);

    const messageReceiveHandler = (message: {
        type: string;
        senderId: string;
        data: any;
    }) => {
        cast.framework.CastReceiverContext.getInstance().sendCustomMessage(
            'urn:x-cast:pair-request',
            message.senderId,
            {
                code: digits.join(''),
            }
        );
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
            devicePayload = await castGateway.getCastData(`${digits.join('')}`);
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
        for (const key in payloadObj) {
            window.localStorage.setItem(key, payloadObj[key]);
        }
    };

    const advertisePublicKey = async (publicKeyB64: string) => {
        // hey client, we exist!
        try {
            await castGateway.advertisePublicKey(
                `${digits.join('')}`,
                publicKeyB64
            );
        } catch (e) {
            return;
        }

        setCodeGeneratedAt(new Date());
        setCodePending(false);
    };

    const router = useRouter();

    useEffect(() => {
        if (digits.length < 1 || !publicKeyB64 || !privateKeyB64) return;

        const interval = setInterval(async () => {
            const data = await pollForCastData();

            if (!data) return;

            storePayloadLocally(data);
            await router.push('/slideshow');
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
                codeGeneratedAt.getTime() + REFRESH_INTERVAL - now.getTime();

            if (timeLeft > 0) {
                const percentage = (timeLeft / REFRESH_INTERVAL) * 100;

                setBorderWidthPercentage(percentage);
            }
        }, 1000);

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
                        {codePending ? (
                            <EnteSpinner />
                        ) : (
                            <>
                                <LargeType chars={digits} />
                                <TimerBar percentage={borderWidthPercentage} />
                            </>
                        )}
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
                    <div
                        style={{
                            position: 'fixed',
                            bottom: '20px',
                            right: '20px',
                            backgroundColor: 'white',
                            display: 'flex',
                            justifyContent: 'center',
                            alignItems: 'center',
                            padding: '10px',
                            borderRadius: '10px',
                        }}>
                        <img src="/images/help-qrcode.webp" />
                    </div>
                </div>
            </div>
        </>
    );
}
