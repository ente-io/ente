import React, { useState } from 'react';
import Container from 'components/Container';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import SubmitButton from './SubmitButton';
import { TextField, Typography } from '@mui/material';

interface Props {
    callback: (
        passphrase: string,
        setFieldError: FormikHelpers<SetPasswordFormValues>['setFieldError']
    ) => Promise<void>;
    buttonText: string;
    back: () => void;
}
export interface SetPasswordFormValues {
    passphrase: string;
    confirm: string;
}
function SetPasswordForm(props: Props) {
    const [loading, setLoading] = useState(false);

    const onSubmit = async (
        values: SetPasswordFormValues,
        { setFieldError }: FormikHelpers<SetPasswordFormValues>
    ) => {
        setLoading(true);
        try {
            const { passphrase, confirm } = values;
            if (passphrase === confirm) {
                await props.callback(passphrase, setFieldError);
            } else {
                setFieldError('confirm', constants.PASSPHRASE_MATCH_ERROR);
            }
        } catch (e) {
            setFieldError('confirm', `${constants.UNKNOWN_ERROR} ${e.message}`);
        } finally {
            setLoading(false);
        }
    };

    return (
        <Formik<SetPasswordFormValues>
            initialValues={{ passphrase: '', confirm: '' }}
            validationSchema={Yup.object().shape({
                passphrase: Yup.string().required(constants.REQUIRED),
                confirm: Yup.string().required(constants.REQUIRED),
            })}
            validateOnChange={false}
            validateOnBlur={false}
            onSubmit={onSubmit}>
            {({ values, errors, handleChange, handleSubmit }) => (
                <form
                    style={{ width: '100%' }}
                    noValidate
                    onSubmit={handleSubmit}>
                    <Container disableGutters>
                        <Typography mb={2}>
                            {constants.ENTER_ENC_PASSPHRASE}
                        </Typography>
                        <Typography mb={2}>
                            {constants.PASSPHRASE_DISCLAIMER()}
                        </Typography>
                        <Container>
                            <TextField
                                margin="normal"
                                fullWidth
                                type="password"
                                label={constants.PASSPHRASE_HINT}
                                value={values.passphrase}
                                onChange={handleChange('passphrase')}
                                error={Boolean(errors.passphrase)}
                                helperText={errors.passphrase}
                                autoFocus
                                disabled={loading}
                            />
                            <TextField
                                fullWidth
                                type="password"
                                label={constants.RE_ENTER_PASSPHRASE}
                                value={values.confirm}
                                onChange={handleChange('confirm')}
                                disabled={loading}
                                error={Boolean(errors.confirm)}
                                helperText={errors.confirm}
                            />
                            <SubmitButton loading={loading}>
                                {props.buttonText}
                            </SubmitButton>
                        </Container>
                    </Container>
                </form>
            )}
        </Formik>
    );
}
export default SetPasswordForm;
