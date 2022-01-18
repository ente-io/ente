import MessageDialog from 'components/MessageDialog';
import SubmitButton from 'components/SubmitButton';
import { REPORT_REASON } from 'constants/publicCollection';
import { Formik, FormikHelpers } from 'formik';
import { PublicCollectionGalleryContext } from 'pages/shared-album';
import React, { useContext, useState } from 'react';
import { Form, FormControl } from 'react-bootstrap';
import { reportAbuse } from 'services/publicCollectionService';
import { AbuseReportRequest } from 'types/publicCollection';
import constants from 'utils/strings/constants';
import * as Yup from 'yup';

interface Iprops {
    url;
    show: boolean;
    close: () => void;
}

export function AbuseReportForm({ show, close, url }: Iprops) {
    const [loading, setLoading] = useState(false);
    const publicCollectionGalleryContent = useContext(
        PublicCollectionGalleryContext
    );

    const submitReport = async (
        { url, reason, comment }: AbuseReportRequest,
        { setFieldError }: FormikHelpers<AbuseReportRequest>
    ) => {
        try {
            console.log({ url, reason, comment });
            setLoading(true);
            if (reason === REPORT_REASON.OTHER && !comment) {
                setFieldError(
                    'comment',
                    constants.OTHER_REASON_REQUIRES_COMMENTS
                );
                return;
            }
            await reportAbuse(
                publicCollectionGalleryContent.token,
                url,
                reason,
                comment
            );
            close();
            publicCollectionGalleryContent.setDialogMessage({
                title: constants.REPORT_SUBMIT_SUCCESS_TITLE,
                content: constants.REPORT_SUBMIT_SUCCESS_CONTENT,
                close: { text: constants.CLOSE },
            });
        } catch (e) {
            setFieldError('comment', constants.REPORT_SUBMIT_FAILED);
        } finally {
            setLoading(false);
        }
        publicCollectionGalleryContent.setDialogMessage({
            title: constants.REPORT_SUBMIT_SUCCESS_TITLE,
            content: constants.REPORT_SUBMIT_SUCCESS_CONTENT,
            close: { text: constants.CLOSE },
        });
    };
    return (
        <MessageDialog
            show={show}
            onHide={close}
            attributes={{
                title: 'abuse report',
                staticBackdrop: true,
            }}>
            <div style={{ padding: '5px 20px' }}>
                <p>{constants.ABUSE_REPORT_DESCRIPTION}</p>
                <Formik<AbuseReportRequest>
                    initialValues={{
                        url,
                        reason: null,
                        comment: '',
                    }}
                    validationSchema={Yup.object().shape({
                        reason: Yup.mixed<keyof typeof REPORT_REASON>()
                            .oneOf(Object.values(REPORT_REASON))
                            .required(constants.REQUIRED),
                    })}
                    validateOnChange={false}
                    validateOnBlur={false}
                    onSubmit={submitReport}>
                    {({
                        values,
                        errors,
                        touched,
                        handleChange,
                        handleSubmit,
                    }): JSX.Element => (
                        <Form noValidate onSubmit={handleSubmit}>
                            <Form.Group controlId="reportForm.url">
                                <Form.Label>Album Url</Form.Label>
                                <Form.Control
                                    type="text"
                                    disabled
                                    value={url}
                                />
                            </Form.Group>
                            <Form.Group controlId="reportForm.reason">
                                <Form.Control
                                    as="select"
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
                                                {String(reason)
                                                    .toLocaleLowerCase()
                                                    .replace('_', ' ')}
                                            </option>
                                        )
                                    )}
                                </Form.Control>
                                <FormControl.Feedback type="invalid">
                                    {'select a reason'}
                                </FormControl.Feedback>
                            </Form.Group>
                            <Form.Group controlId="reportForm.comment">
                                <Form.Control
                                    type="text-area"
                                    placeholder={constants.COMMENT}
                                    as="textarea"
                                    value={values.comment}
                                    onChange={handleChange('comment')}
                                    isInvalid={Boolean(
                                        touched.comment && errors.comment
                                    )}
                                    disabled={loading}
                                />
                                <Form.Control.Feedback type="invalid">
                                    {errors.comment}
                                </Form.Control.Feedback>
                            </Form.Group>

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
