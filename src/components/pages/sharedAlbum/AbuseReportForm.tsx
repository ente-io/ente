import MessageDialog from 'components/MessageDialog';
import SubmitButton from 'components/SubmitButton';
import { Formik } from 'formik';
import React, { useState } from 'react';
import { Form, FormControl } from 'react-bootstrap';
import { reportAbuse } from 'services/publicCollectionService';
import { sleep } from 'utils/common';
import constants from 'utils/strings/constants';
import * as Yup from 'yup';

interface Iprops {
    show: boolean;
    close: () => void;
}

enum REPORT_REASON {
    COPYRIGHT = 'COPYRIGHT',
    CHILD_ABUSE = 'CHILD_ABUSE',
    NUDITY = 'NUDITY',
    OTHER = 'OTHER',
}
interface FormValues {
    reason: REPORT_REASON;
    comment: string;
}
export function AbuseReportForm({ show, close }: Iprops) {
    const [loading, setLoading] = useState(false);

    const handleSubmit = async () => {
        try {
            setLoading(true);
            reportAbuse();
            await sleep(1000);
        } finally {
            setLoading(false);
        }
    };
    console.log(typeof REPORT_REASON);
    return (
        <MessageDialog
            show={show}
            onHide={close}
            attributes={{
                title: 'abuse report',
                staticBackdrop: true,
            }}>
            <div style={{ padding: '5px 20px' }}>
                <p>{constants.RECOVERY_KEY_DESCRIPTION}</p>
                <Formik<FormValues>
                    initialValues={{
                        reason: REPORT_REASON.COPYRIGHT,
                        comment: '',
                    }}
                    validationSchema={Yup.object().shape({
                        email: Yup.mixed<keyof typeof REPORT_REASON>()
                            .oneOf(Object.values(REPORT_REASON))
                            .required(constants.REQUIRED),
                        comment: Yup.string().required(constants.REQUIRED),
                    })}
                    validateOnChange={false}
                    validateOnBlur={false}
                    onSubmit={handleSubmit}>
                    {({
                        values,
                        errors,
                        touched,
                        handleChange,
                        handleSubmit,
                    }): JSX.Element => (
                        <Form noValidate onSubmit={handleSubmit}>
                            <Form.Group controlId="registrationForm.email">
                                <Form.Control
                                    as="select"
                                    placeholder={constants.ENTER_EMAIL}
                                    value={values.reason}
                                    onChange={handleChange('reason')}
                                    isInvalid={Boolean(
                                        touched.reason && errors.reason
                                    )}
                                    autoFocus
                                    disabled={loading}>
                                    <option disabled selected>
                                        select reason
                                    </option>
                                    {Object.values(REPORT_REASON).map(
                                        (reason) => (
                                            <option key={reason} value={reason}>
                                                {String(
                                                    reason
                                                ).toLocaleLowerCase()}
                                            </option>
                                        )
                                    )}
                                </Form.Control>
                                <FormControl.Feedback type="invalid">
                                    {errors.reason}
                                </FormControl.Feedback>
                            </Form.Group>
                            {/* <Form.Group>
                                <Form.Control
                                    type="text-area"
                                    placeholder={constants.PASSPHRASE_HINT}
                                    value={values.passphrase}
                                    onChange={handleChange('passphrase')}
                                    isInvalid={Boolean(
                                        touched.passphrase && errors.passphrase
                                    )}
                                    disabled={loading}
                                />
                                <Form.Control.Feedback type="invalid">
                                    {errors.passphrase}
                                </Form.Control.Feedback>
                            </Form.Group> */}
                            {/* <Form.Group>
                                <Form.Control
                                    type="password"
                                    placeholder={constants.RE_ENTER_PASSPHRASE}
                                    value={values.confirm}
                                    onChange={handleChange('confirm')}
                                    isInvalid={Boolean(
                                        touched.confirm && errors.confirm
                                    )}
                                    disabled={loading}
                                />
                                <Form.Control.Feedback type="invalid">
                                    {errors.confirm}
                                </Form.Control.Feedback>
                            </Form.Group> */}

                            <SubmitButton
                                buttonText={constants.SUBMIT}
                                loading={loading}
                            />
                        </Form>
                    )}
                </Formik>
            </div>
        </MessageDialog>
    );
}
