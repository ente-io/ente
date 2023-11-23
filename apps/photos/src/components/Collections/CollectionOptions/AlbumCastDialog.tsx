import { Typography } from '@mui/material';
import DialogBoxV2 from '@ente/shared/components/DialogBoxV2';
import SingleInputForm, {
    SingleInputFormProps,
} from '@ente/shared/components/SingleInputForm';
import { t } from 'i18next';
import { getKexValue, setKexValue } from '@ente/shared/network/kexService';
import { SESSION_KEYS, getKey } from '@ente/shared/storage/sessionStorage';
import { boxSeal, toB64 } from '@ente/shared/crypto/internal/libsodium';

interface Props {
    show: boolean;
    onHide: () => void;
    currentCollectionId: number;
}

enum AlbumCastError {
    TV_NOT_FOUND = 'TV_NOT_FOUND',
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
            ...window.localStorage,
            sessionKey: getKey(SESSION_KEYS.ENCRYPTION_KEY),
            targetCollectionId: props.currentCollectionId,
        });

        const encryptedPayload = await boxSeal(
            await toB64(new TextEncoder().encode(payload)),
            tvPublicKeyB64
        );

        const encryptedPayloadForTvKexKey = `${pin}_payload`;

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
