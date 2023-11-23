import { Typography } from '@mui/material';
import DialogBoxV2 from '@ente/shared/components/DialogBoxV2';
import SingleInputForm, {
    SingleInputFormProps,
} from '@ente/shared/components/SingleInputForm';
import { t } from 'i18next';
import { getKexValue, setKexValue } from 'services/kexService';
import { SESSION_KEYS, getKey } from '@ente/shared/storage/sessionStorage';
import { boxSeal, toB64 } from '@ente/shared/crypto/internal/libsodium';

interface Props {
    show: boolean;
    onHide: () => void;
    currentCollectionId: number;
}

export default function AlbumCastDialog(props: Props) {
    const onSubmit: SingleInputFormProps['callback'] = async (
        value,
        setFieldError
    ) => {
        try {
            await doCast(value);
            props.onHide();
        } catch (e) {
            setFieldError(t('UNKNOWN_ERROR'));
        }
    };

    const doCast = async (pin: string) => {
        // does the TV exist? have they advertised their existence?
        const tvPublicKeyKexKey = `${pin}_pubkey`;

        const tvPublicKeyB64 = await getKexValue(tvPublicKeyKexKey);
        if (!tvPublicKeyB64) {
            throw new Error('Failed to get TV public key');
        }

        // ok, they exist. let's give them the good stuff.
        const payload = JSON.stringify({
            ...window.localStorage,
            sessionKey: getKey(SESSION_KEYS.ENCRYPTION_KEY),
            targetCollectionId: props.currentCollectionId,
        });

        console.log('payload created', payload);
        console.log('tv public key b64', tvPublicKeyB64);

        const encryptedPayload = await boxSeal(
            await toB64(new TextEncoder().encode(payload)),
            tvPublicKeyB64
        );

        console.log('payload encrypted', encryptedPayload);

        const encryptedPayloadForTvKexKey = `${pin}_payload`;

        console.log('setting kex');

        // hey TV, we acknowlege you!
        await setKexValue(encryptedPayloadForTvKexKey, encryptedPayload);
    };

    return (
        <DialogBoxV2
            sx={{ zIndex: 1600 }}
            open={props.show}
            onClose={props.onHide}
            attributes={{
                title: t('CAST_ALBUM_TO_TV'),
            }}>
            <Typography>{t('ENTER_CAST_PIN_CODE')}</Typography>
            <SingleInputForm
                callback={onSubmit}
                fieldType="text"
                placeholder={'123456'}
                buttonText={t('PAIR_DEVICE_TO_TV')}
                submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
            />
        </DialogBoxV2>
    );
}
