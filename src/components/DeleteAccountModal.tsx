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
import { Trans, useTranslation } from 'react-i18next';

interface Iprops {
    onClose: () => void;
    open: boolean;
}
const DeleteAccountModal = ({ open, onClose }: Iprops) => {
    const { t } = useTranslation();
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
            close: { variant: 'danger' },
            content: t('UNKNOWN_ERROR'),
        });

    const initiateDelete = async () => {
        try {
            askToMailForDeletion();
            return;
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
            content: t('CONFIRM_ACCOUNT_DELETION_MESSAGE'),
            proceed: {
                text: t('DELETE'),
                action: solveChallengeAndDeleteAccount,
                variant: 'danger',
            },
            close: { text: t('CANCEL') },
        });
    };

    const askToMailForDeletion = () => {
        setDialogMessage({
            title: t('DELETE_ACCOUNT'),
            content: (
                <Trans i18nKey="DELETE_ACCOUNT_MESSAGE">
                    <p>
                        Please send an email to
                        <Link href="mailto:account-deletion@ente.io">
                            account-deletion@ente.io
                        </Link>
                        from your registered email address.
                    </p>
                    <p>Your request will be processed within 72 hours.</p>
                </Trans>
            ),
            proceed: {
                text: t('DELETE'),
                action: () => {
                    initiateEmail('account-deletion@ente.io');
                },
                variant: 'danger',
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

                    <Typography color="text.secondary" px={1.5}>
                        <Trans i18nKey="ASK_FOR_FEEDBACK">
                            <p>
                                We'll be sorry to see you go. Are you facing
                                some issue?
                            </p>
                            <p>
                                Please write to us at{' '}
                                <Link href="mailto:feedback@ente.io">
                                    feedback@ente.io
                                </Link>
                                , maybe there is a way we can help.
                            </p>
                        </Trans>
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
                            color="danger"
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
