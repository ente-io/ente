import { Button, Link, Stack } from '@mui/material';
import { AppContext } from 'pages/_app';
import { useContext, useEffect, useRef, useState } from 'react';
import { preloadImage, initiateEmail } from 'utils/common';
import { deleteAccount, getAccountDeleteChallenge } from 'services/userService';
import { logError } from '@ente/shared/sentry';
import { decryptDeleteAccountChallenge } from 'utils/crypto';
import { Trans } from 'react-i18next';
import { t } from 'i18next';
import { DELETE_ACCOUNT_EMAIL } from '@ente/shared/constants/urls';
import DialogBoxV2 from '@ente/shared/components/DialogBoxV2';
import * as Yup from 'yup';
import { Formik, FormikHelpers } from 'formik';
import DropdownInput, { DropdownOption } from './DropdownInput';
import MultilineInput from './MultilineInput';
import { CheckboxInput } from './CheckboxInput';
import EnteButton from '@ente/shared/components/EnteButton';
import { GalleryContext } from 'pages/gallery';
import { logoutUser } from '@ente/accounts/services/user';

interface Iprops {
    onClose: () => void;
    open: boolean;
}

interface FormValues {
    reason: string;
    feedback: string;
}

enum DELETE_REASON {
    MISSING_FEATURE = "It's missing a key feature that I need",
    BROKEN_BEHAVIOR = 'The app or a certain feature does not behave as I think it should',
    FOUND_ANOTHER_SERVICE = 'I found another service that I like better',
    NOT_LISTED = "My reason isn't listed",
}

const getReasonOptions = (): DropdownOption<DELETE_REASON>[] => {
    return Object.keys(DELETE_REASON).map((reason) => ({
        label: t(`DELETE_REASON.${reason}`),
        value: DELETE_REASON[reason],
    }));
};

const DeleteAccountModal = ({ open, onClose }: Iprops) => {
    const { setDialogBoxAttributesV2, isMobile } = useContext(AppContext);
    const { authenticateUser } = useContext(GalleryContext);
    const [loading, setLoading] = useState(false);
    const deleteAccountChallenge = useRef<string>();

    const [acceptDataDeletion, setAcceptDataDeletion] = useState(false);
    const reasonAndFeedbackRef = useRef<{ reason: string; feedback: string }>();

    useEffect(() => {
        preloadImage('/images/delete-account');
    }, []);

    const somethingWentWrong = () =>
        setDialogBoxAttributesV2({
            title: t('ERROR'),
            close: { variant: 'critical' },
            content: t('UNKNOWN_ERROR'),
        });

    const initiateDelete = async (
        { reason, feedback }: FormValues,
        { setFieldError }: FormikHelpers<FormValues>
    ) => {
        try {
            feedback = feedback.trim();
            if (feedback.length === 0) {
                switch (reason) {
                    case DELETE_REASON.FOUND_ANOTHER_SERVICE:
                        setFieldError(
                            'feedback',
                            t('FEEDBACK_REQUIRED_FOUND_ANOTHER_SERVICE')
                        );
                        break;
                    default:
                        setFieldError('feedback', t('FEEDBACK_REQUIRED'));
                }
                return;
            }
            setLoading(true);
            reasonAndFeedbackRef.current = { reason, feedback };
            const deleteChallengeResponse = await getAccountDeleteChallenge();
            deleteAccountChallenge.current =
                deleteChallengeResponse.encryptedChallenge;
            if (deleteChallengeResponse.allowDelete) {
                authenticateUser(confirmAccountDeletion);
            } else {
                askToMailForDeletion();
            }
        } catch (e) {
            logError(e, 'Error while initiating account deletion');
            somethingWentWrong();
        } finally {
            setLoading(false);
        }
    };

    const confirmAccountDeletion = () => {
        setDialogBoxAttributesV2({
            title: t('DELETE_ACCOUNT'),
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
        setDialogBoxAttributesV2({
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

    const solveChallengeAndDeleteAccount = async (
        setLoading: (value: boolean) => void
    ) => {
        try {
            setLoading(true);
            const decryptedChallenge = await decryptDeleteAccountChallenge(
                deleteAccountChallenge.current
            );
            const { reason, feedback } = reasonAndFeedbackRef.current;
            await deleteAccount(decryptedChallenge, reason, feedback);
            logoutUser();
        } catch (e) {
            logError(e, 'solveChallengeAndDeleteAccount failed');
            somethingWentWrong();
        } finally {
            setLoading(false);
        }
    };

    return (
        <>
            <DialogBoxV2
                fullWidth
                open={open}
                onClose={onClose}
                fullScreen={isMobile}
                attributes={{
                    title: t('DELETE_ACCOUNT'),
                    secondary: {
                        action: onClose,
                        text: t('CANCEL'),
                    },
                }}>
                <Formik<FormValues>
                    initialValues={{
                        reason: '',
                        feedback: '',
                    }}
                    validationSchema={Yup.object().shape({
                        reason: Yup.string().required(t('REQUIRED')),
                    })}
                    validateOnChange={false}
                    validateOnBlur={false}
                    onSubmit={initiateDelete}>
                    {({
                        values,
                        errors,
                        handleChange,
                        handleSubmit,
                    }): JSX.Element => (
                        <form noValidate onSubmit={handleSubmit}>
                            <Stack spacing={'24px'}>
                                <DropdownInput
                                    options={getReasonOptions()}
                                    label={t('DELETE_ACCOUNT_REASON_LABEL')}
                                    placeholder={t(
                                        'DELETE_ACCOUNT_REASON_PLACEHOLDER'
                                    )}
                                    selected={values.reason}
                                    setSelected={handleChange('reason')}
                                    messageProps={{ color: 'critical.main' }}
                                    message={errors.reason}
                                />
                                <MultilineInput
                                    label={t('DELETE_ACCOUNT_FEEDBACK_LABEL')}
                                    placeholder={t(
                                        'DELETE_ACCOUNT_FEEDBACK_PLACEHOLDER'
                                    )}
                                    value={values.feedback}
                                    onChange={handleChange('feedback')}
                                    message={errors.feedback}
                                    messageProps={{ color: 'critical.main' }}
                                    rowCount={3}
                                />
                                <CheckboxInput
                                    checked={acceptDataDeletion}
                                    onChange={setAcceptDataDeletion}
                                    label={t(
                                        'CONFIRM_DELETE_ACCOUNT_CHECKBOX_LABEL'
                                    )}
                                />
                                <Stack spacing={'8px'}>
                                    <EnteButton
                                        type="submit"
                                        size="large"
                                        color="critical"
                                        disabled={!acceptDataDeletion}
                                        loading={loading}>
                                        {t('CONFIRM_DELETE_ACCOUNT')}
                                    </EnteButton>
                                    <Button
                                        size="large"
                                        color={'secondary'}
                                        onClick={onClose}>
                                        {t('CANCEL')}
                                    </Button>
                                </Stack>
                            </Stack>
                        </form>
                    )}
                </Formik>
            </DialogBoxV2>
        </>
    );
};

export default DeleteAccountModal;
