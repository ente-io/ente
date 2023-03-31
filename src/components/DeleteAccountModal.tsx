import NoAccountsIcon from '@mui/icons-material/NoAccountsOutlined';
import TickIcon from '@mui/icons-material/Done';
import {
    Dialog,
    DialogContent,
    Typography,
    Button,
    Stack,
    Link,
} from '@mui/material';
import { AppContext } from 'pages/_app';
import React, { useContext, useEffect, useState } from 'react';
import { preloadImage, initiateEmail } from 'utils/common';
import VerticallyCentered from './Container';
import DialogTitleWithCloseButton from './DialogBox/TitleWithCloseButton';
import {
    deleteAccount,
    getAccountDeleteChallenge,
    logoutUser,
} from 'services/userService';
import AuthenticateUserModal from './AuthenticateUserModal';
import { logError } from 'utils/sentry';
import { decryptDeleteAccountChallenge } from 'utils/crypto';
import { Trans } from 'react-i18next';
import { t } from 'i18next';
import { DELETE_ACCOUNT_EMAIL, FEEDBACK_EMAIL } from 'constants/urls';

interface Iprops {
    onClose: () => void;
    open: boolean;
}
const DeleteAccountModal = ({ open, onClose }: Iprops) => {
    const { setDialogMessage, isMobile } = useContext(AppContext);
    const [authenticateUserModalView, setAuthenticateUserModalView] =
        useState(false);
    const [deleteAccountChallenge, setDeleteAccountChallenge] = useState('');

    const openAuthenticateUserModal = () => setAuthenticateUserModalView(true);
    const closeAuthenticateUserModal = () =>
        setAuthenticateUserModalView(false);

    useEffect(() => {
        preloadImage('/images/delete-account');
    }, []);

    const sendFeedbackMail = () => initiateEmail('feedback@ente.io');

    const somethingWentWrong = () =>
        setDialogMessage({
            title: t('ERROR'),
            close: { variant: 'critical' },
            content: t('UNKNOWN_ERROR'),
        });

    const initiateDelete = async () => {
        try {
            const deleteChallengeResponse = await getAccountDeleteChallenge();
            setDeleteAccountChallenge(
                deleteChallengeResponse.encryptedChallenge
            );
            if (deleteChallengeResponse.allowDelete) {
                openAuthenticateUserModal();
            } else {
                askToMailForDeletion();
            }
        } catch (e) {
            logError(e, 'Error while initiating account deletion');
            somethingWentWrong();
        }
    };

    const confirmAccountDeletion = () => {
        setDialogMessage({
            title: t('CONFIRM_ACCOUNT_DELETION_TITLE'),
            content: <Trans i18nKey="CONFIRM_ACCOUNT_DELETION_MESSAGE" />,
            proceed: {
                text: t('DELETE'),
                action: solveChallengeAndDeleteAccount,
                variant: 'critical',
            },
            close: { text: t('CANCEL') },
        });
    };

    const askToMailForDeletion = () => {
        setDialogMessage({
            title: t('DELETE_ACCOUNT'),
            content: (
                <Trans
                    i18nKey="DELETE_ACCOUNT_MESSAGE"
                    components={{
                        a: <Link href={`mailto:${DELETE_ACCOUNT_EMAIL}`} />,
                    }}
                    values={{ emailID: DELETE_ACCOUNT_EMAIL }}
                />
            ),
            proceed: {
                text: t('DELETE'),
                action: () => {
                    initiateEmail('account-deletion@ente.io');
                },
                variant: 'critical',
            },
            close: { text: t('CANCEL') },
        });
    };

    const solveChallengeAndDeleteAccount = async () => {
        try {
            const decryptedChallenge = await decryptDeleteAccountChallenge(
                deleteAccountChallenge
            );
            await deleteAccount(decryptedChallenge);
            logoutUser();
        } catch (e) {
            logError(e, 'solveChallengeAndDeleteAccount failed');
            somethingWentWrong();
        }
    };

    return (
        <>
            <Dialog
                fullWidth
                open={open}
                onClose={onClose}
                maxWidth="xs"
                fullScreen={isMobile}>
                <DialogTitleWithCloseButton onClose={onClose}>
                    <Typography variant="h3" fontWeight={'bold'}>
                        {t('DELETE_ACCOUNT')}
                    </Typography>
                </DialogTitleWithCloseButton>
                <DialogContent>
                    <VerticallyCentered>
                        <img
                            height={256}
                            src="/images/delete-account/1x.png"
                            srcSet="/images/delete-account/2x.png 2x,
                            /images/delete-account/3x.png 3x"
                        />
                    </VerticallyCentered>

                    <Typography color="text.muted" px={1.5}>
                        <Trans
                            i18nKey="ASK_FOR_FEEDBACK"
                            components={{
                                a: <Link href={`mailto:${FEEDBACK_EMAIL}`} />,
                            }}
                            values={{ emailID: FEEDBACK_EMAIL }}
                        />
                    </Typography>

                    <Stack spacing={1} px={2} sx={{ width: '100%' }}>
                        <Button
                            size="large"
                            color="accent"
                            onClick={sendFeedbackMail}
                            startIcon={<TickIcon />}>
                            {t('SEND_FEEDBACK')}
                        </Button>
                        <Button
                            size="large"
                            variant="outlined"
                            color="critical"
                            onClick={initiateDelete}
                            startIcon={<NoAccountsIcon />}>
                            {t('DELETE_ACCOUNT')}
                        </Button>
                    </Stack>
                </DialogContent>
            </Dialog>
            <AuthenticateUserModal
                open={authenticateUserModalView}
                onClose={closeAuthenticateUserModal}
                onAuthenticate={confirmAccountDeletion}
            />
        </>
    );
};

export default DeleteAccountModal;
