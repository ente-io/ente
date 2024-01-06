import { Typography } from '@mui/material';
import DialogBoxV2 from '@ente/shared/components/DialogBoxV2';
import SingleInputForm, {
    SingleInputFormProps,
} from '@ente/shared/components/SingleInputForm';
import { t } from 'i18next';
import { getKexValue, setKexValue } from '@ente/shared/network/kexService';
import { boxSeal, toB64 } from '@ente/shared/crypto/internal/libsodium';
import { loadSender } from '@ente/shared/hooks/useCastSender';
import { useEffect, useState } from 'react';
import EnteButton from '@ente/shared/components/EnteButton';
import EnteSpinner from '@ente/shared/components/EnteSpinner';
import { VerticallyCentered } from '@ente/shared/components/Container';
import { logError } from '@ente/shared/sentry';
import { LS_KEYS, getData } from '@ente/shared/storage/localStorage';
import { Collection } from 'types/collection';

interface Props {
    show: boolean;
    onHide: () => void;
    currentCollection: Collection;
}

enum AlbumCastError {
    TV_NOT_FOUND = 'TV_NOT_FOUND',
}

declare global {
    interface Window {
        chrome: any;
    }
}

export default function AlbumCastDialog(props: Props) {
    const [view, setView] = useState<
        'choose' | 'auto' | 'pin' | 'auto-cast-error'
    >('choose');

    const [browserCanCast, setBrowserCanCast] = useState(false);

    const onSubmit: SingleInputFormProps['callback'] = async (
        value,
        setFieldError
    ) => {
        try {
            await doCast(value);
            props.onHide();
        } catch (e) {
            const error = e as Error;
            let fieldError: string;
            switch (error.message) {
                case AlbumCastError.TV_NOT_FOUND:
                    fieldError = t('TV_NOT_FOUND');
                    break;
                default:
                    fieldError = t('UNKNOWN_ERROR');
                    break;
            }

            setFieldError(fieldError);
        }
    };

    const doCast = async (pin: string) => {
        // does the TV exist? have they advertised their existence?
        const tvPublicKeyKexKey = `${pin}_pubkey`;

        const tvPublicKeyB64 = await getKexValue(tvPublicKeyKexKey);
        if (!tvPublicKeyB64) {
            throw new Error(AlbumCastError.TV_NOT_FOUND);
        }

        // ok, they exist. let's give them the good stuff.
        const payload = JSON.stringify({
            user: JSON.stringify(getData(LS_KEYS.USER)),
            targetCollectionId: props.currentCollection.id,
            targetCollectionKey: props.currentCollection.key,
        });

        const encryptedPayload = await boxSeal(
            await toB64(new TextEncoder().encode(payload)),
            tvPublicKeyB64
        );

        const encryptedPayloadForTvKexKey = `${pin}_payload`;

        // hey TV, we acknowlege you!
        await setKexValue(encryptedPayloadForTvKexKey, encryptedPayload);
    };

    useEffect(() => {
        if (view === 'auto') {
            loadSender().then(async (sender) => {
                const { cast } = sender;

                const instance = await cast.framework.CastContext.getInstance();
                try {
                    await instance.requestSession();
                } catch (e) {
                    setView('auto-cast-error');
                    logError(e, 'Error requesting session');
                    return;
                }
                const session = instance.getCurrentSession();
                console.log(session);
                session.addMessageListener(
                    'urn:x-cast:pair-request',
                    (namespace, message) => {
                        const data = message;
                        const obj = JSON.parse(data);
                        const code = obj.code;

                        if (code) {
                            doCast(code)
                                .then(() => {
                                    setView('choose');
                                    props.onHide();
                                })
                                .catch((e) => {
                                    setView('auto-cast-error');
                                    logError(e, 'Error casting to TV');
                                });
                        }
                    }
                );

                session
                    .sendMessage('urn:x-cast:pair-request', {})
                    .then(() => {
                        console.log('Message sent successfully');
                    })
                    .catch((error) => {
                        logError(error, 'Error sending message');
                    });
            });
        }
    }, [view]);

    useEffect(() => {
        setBrowserCanCast(!!window.chrome);
    }, [props.show]);

    return (
        <DialogBoxV2
            sx={{ zIndex: 1600 }}
            open={props.show}
            onClose={props.onHide}
            attributes={{
                title: t('CAST_ALBUM_TO_TV'),
            }}>
            {view === 'choose' && (
                <>
                    {browserCanCast && (
                        <>
                            <Typography color={'text.muted'}>
                                {t(
                                    'AUTO_CAST_PAIR_REQUIRES_CONNECTION_TO_GOOGLE'
                                )}
                            </Typography>

                            <EnteButton
                                style={{
                                    marginBottom: '1rem',
                                }}
                                onClick={() => {
                                    setView('auto');
                                }}>
                                {t('AUTO_CAST_PAIR')}
                            </EnteButton>
                        </>
                    )}
                    <Typography color="text.muted">
                        {t('PAIR_WITH_PIN_WORKS_FOR_ANY_LARGE_SCREEN_DEVICE')}
                    </Typography>

                    <EnteButton
                        onClick={() => {
                            setView('pin');
                        }}>
                        {t('PAIR_WITH_PIN')}
                    </EnteButton>
                </>
            )}
            {view === 'auto' && (
                <VerticallyCentered gap="1rem">
                    <EnteSpinner />
                    <Typography>{t('CHOOSE_DEVICE_FROM_BROWSER')}</Typography>
                    <EnteButton
                        variant="text"
                        onClick={() => {
                            setView('choose');
                        }}>
                        {t('GO_BACK')}
                    </EnteButton>
                </VerticallyCentered>
            )}
            {view === 'auto-cast-error' && (
                <VerticallyCentered gap="1rem">
                    <Typography>{t('CAST_AUTO_PAIR_FAILED')}</Typography>
                    <EnteButton
                        variant="text"
                        onClick={() => {
                            setView('choose');
                        }}>
                        {t('GO_BACK')}
                    </EnteButton>
                </VerticallyCentered>
            )}
            {view === 'pin' && (
                <>
                    <Typography>{t('VISIT_CAST_ENTE_IO')}</Typography>
                    <Typography>{t('ENTER_CAST_PIN_CODE')}</Typography>
                    <SingleInputForm
                        callback={onSubmit}
                        fieldType="text"
                        placeholder={'123456'}
                        buttonText={t('PAIR_DEVICE_TO_TV')}
                        submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                    />
                    <EnteButton
                        variant="text"
                        onClick={() => {
                            setView('choose');
                        }}>
                        {t('GO_BACK')}
                    </EnteButton>
                </>
            )}
        </DialogBoxV2>
    );
}
