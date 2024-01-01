import DialogBoxV2 from '@ente/shared/components/DialogBoxV2';
import { AppContext } from 'pages/_app';
import { useContext } from 'react';
import { PasskeysContext } from '.';
import SingleInputForm from '@ente/shared/components/SingleInputForm';
import { t } from 'i18next';
import { renamePasskey } from 'services/passkeysService';

interface IProps {
    open: boolean;
    onClose: () => void;
}

const RenamePasskeyModal = (props: IProps) => {
    const { isMobile } = useContext(AppContext);
    const { selectedPasskey } = useContext(PasskeysContext);

    const onSubmit = async (inputValue: string) => {
        if (!selectedPasskey) return;
        try {
            await renamePasskey(selectedPasskey.id, inputValue);
        } catch (error) {
            console.error(error);
            return;
        }

        props.onClose();
    };

    return (
        <DialogBoxV2
            fullWidth
            open={props.open}
            onClose={props.onClose}
            fullScreen={isMobile}
            attributes={{
                title: t('RENAME_PASSKEY'),
                secondary: {
                    action: props.onClose,
                    text: t('CANCEL'),
                },
            }}>
            <SingleInputForm
                initialValue={selectedPasskey?.friendlyName}
                callback={onSubmit}
                placeholder={t('ENTER_PASSKEY_NAME')}
                buttonText={t('RENAME')}
                fieldType="text"
                secondaryButtonAction={props.onClose}
                submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
            />
        </DialogBoxV2>
    );
};

export default RenamePasskeyModal;
