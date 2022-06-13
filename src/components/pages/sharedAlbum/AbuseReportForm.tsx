import DialogBox from 'components/DialogBox';
import SubmitButton from 'components/SubmitButton';
import { REPORT_REASON } from 'constants/publicCollection';
import { Formik, FormikHelpers } from 'formik';
import { PublicCollectionGalleryContext } from 'utils/publicCollectionGallery';
import React, { useContext, useState } from 'react';
import { Col, Form, FormControl, Row } from 'react-bootstrap';
import { reportAbuse } from 'services/publicCollectionService';
import constants from 'utils/strings/constants';
import * as Yup from 'yup';
import { styled } from '@mui/material';
import { AbuseReportDetails, AbuseReportRequest } from 'types/publicCollection';
import { AppContext } from 'pages/_app';

interface Iprops {
    url: string;
    show: boolean;
    close: () => void;
}

interface FormValues
    extends Omit<AbuseReportRequest, 'details'>,
        AbuseReportDetails {
    terms: {
        1: boolean;
        2: boolean;
        3: boolean;
    };
}

const defaultInitialValues: FormValues = {
    url: '',
    reason: null,
    fullName: '',
    email: '',
    comment: '',
    signature: '',
    onBehalfOf: '',
    jobTitle: '',
    address: {
        street: '',
        city: '',
        state: '',
        country: '',
        postalCode: '',
        phone: '',
    },
    terms: {
        1: false,
        2: false,
        3: false,
    },
};

const Wrapper = styled('div')`
    padding: 5px 20px;
`;

export function AbuseReportForm({ show, close, url }: Iprops) {
    const [loading, setLoading] = useState(false);
    const appContext = useContext(AppContext);
    const publicCollectionGalleryContent = useContext(
        PublicCollectionGalleryContext
    );

    const submitReport = async (
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        { url, reason, terms, ...details }: FormValues,
        { setFieldError }: FormikHelpers<FormValues>
    ) => {
        try {
            setLoading(true);
            if (reason === REPORT_REASON.MALICIOUS_CONTENT) {
                details.address = undefined;
                details.onBehalfOf = undefined;
                details.jobTitle = undefined;
            }
            if (!details.comment) {
                details.comment = undefined;
            }
            await reportAbuse(
                publicCollectionGalleryContent.token,
                url,
                reason,
                details
            );
            close();
            appContext.setDialogMessage({
                title: constants.REPORT_SUBMIT_SUCCESS_TITLE,
                content: constants.REPORT_SUBMIT_SUCCESS_CONTENT,
                close: { text: constants.OK },
            });
        } catch (e) {
            setFieldError('signature', constants.REPORT_SUBMIT_FAILED);
        } finally {
            setLoading(false);
        }
    };

    return (
        <DialogBox
            open={show}
            size="lg"
            onClose={close}
            attributes={{
                title: constants.ABUSE_REPORT,
            }}>
            <Wrapper>
                <h6>{constants.ABUSE_REPORT_DESCRIPTION}</h6>
                <Formik<FormValues>
                    initialValues={{
                        ...defaultInitialValues,
                        url,
                    }}
                    validationSchema={Yup.object().shape({
                        reason: Yup.mixed<keyof typeof REPORT_REASON>()
                            .oneOf(Object.values(REPORT_REASON))
                            .required(constants.REQUIRED),
                        url: Yup.string().required(constants.REQUIRED),
                        fullName: Yup.string().required(constants.REQUIRED),
                        email: Yup.string()
                            .email()
                            .required(constants.REQUIRED),
                        comment: Yup.string(),
                        signature: Yup.string().required(constants.REQUIRED),
                        onBehalfOf: Yup.string().when('reason', {
                            is: REPORT_REASON.COPYRIGHT,
                            then: Yup.string().required(constants.REQUIRED),
                        }),
                        jobTitle: Yup.string().when('reason', {
                            is: REPORT_REASON.COPYRIGHT,
                            then: Yup.string().required(constants.REQUIRED),
                        }),
                        address: Yup.object().when('reason', {
                            is: REPORT_REASON.COPYRIGHT,
                            then: Yup.object().shape({
                                city: Yup.string().required(constants.REQUIRED),
                                state: Yup.string().required(
                                    constants.REQUIRED
                                ),
                                country: Yup.string().required(
                                    constants.REQUIRED
                                ),
                                postalCode: Yup.string().required(
                                    constants.REQUIRED
                                ),
                                phone: Yup.string().required(
                                    constants.REQUIRED
                                ),
                            }),
                        }),
                        terms: Yup.object().when('reason', {
                            is: REPORT_REASON.COPYRIGHT,
                            then: Yup.object().shape({
                                1: Yup.boolean(),
                                2: Yup.boolean(),
                                3: Yup.boolean(),
                            }),
                        }),
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
                                <Form.Label>{constants.ALBUM_URL}</Form.Label>
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
                                                {constants[reason]}
                                            </option>
                                        )
                                    )}
                                </Form.Control>
                                <FormControl.Feedback type="invalid">
                                    {constants.SELECT_REASON}
                                </FormControl.Feedback>
                            </Form.Group>
                            <Row>
                                <Col md={6}>
                                    <Form.Group controlId="reportForm.fullName">
                                        <Form.Control
                                            type="text"
                                            placeholder={
                                                constants.ENTER_FULL_NAME
                                            }
                                            value={values.fullName}
                                            onChange={handleChange('fullName')}
                                            isInvalid={Boolean(
                                                touched.fullName &&
                                                    errors.fullName
                                            )}
                                            disabled={loading}
                                        />
                                        <Form.Control.Feedback type="invalid">
                                            {errors.fullName}
                                        </Form.Control.Feedback>
                                    </Form.Group>
                                </Col>
                                <Col md={6}>
                                    <Form.Group controlId="reportForm.email">
                                        <Form.Control
                                            type="text"
                                            placeholder={
                                                constants.ENTER_EMAIL_ADDRESS
                                            }
                                            value={values.email}
                                            onChange={handleChange('email')}
                                            isInvalid={Boolean(
                                                touched.email && errors.email
                                            )}
                                            disabled={loading}
                                        />
                                        <Form.Control.Feedback type="invalid">
                                            {errors.email}
                                        </Form.Control.Feedback>
                                    </Form.Group>
                                </Col>
                            </Row>

                            {values.reason === REPORT_REASON.COPYRIGHT && (
                                <>
                                    <Row>
                                        <Col md={6}>
                                            {' '}
                                            <Form.Group controlId="reportForm.onBehalfOf">
                                                <Form.Control
                                                    type="text"
                                                    placeholder={
                                                        constants.ENTER_ON_BEHALF_OF
                                                    }
                                                    value={values.onBehalfOf}
                                                    onChange={handleChange(
                                                        'onBehalfOf'
                                                    )}
                                                    isInvalid={Boolean(
                                                        touched.onBehalfOf &&
                                                            errors.onBehalfOf
                                                    )}
                                                    disabled={loading}
                                                />
                                                <Form.Control.Feedback type="invalid">
                                                    {errors.onBehalfOf}
                                                </Form.Control.Feedback>
                                            </Form.Group>
                                        </Col>
                                        <Col md={6}>
                                            <Form.Group controlId="reportForm.jobTitle">
                                                <Form.Control
                                                    type="text"
                                                    placeholder={
                                                        constants.ENTER_JOB_TITLE
                                                    }
                                                    value={values.jobTitle}
                                                    onChange={handleChange(
                                                        'jobTitle'
                                                    )}
                                                    isInvalid={Boolean(
                                                        touched.jobTitle &&
                                                            errors.jobTitle
                                                    )}
                                                    disabled={loading}
                                                />
                                                <Form.Control.Feedback type="invalid">
                                                    {errors.jobTitle}
                                                </Form.Control.Feedback>
                                            </Form.Group>
                                        </Col>
                                    </Row>
                                    <Row>
                                        <Col md={6}>
                                            <Form.Group controlId="reportForm.address">
                                                <Form.Control
                                                    type="text"
                                                    placeholder={
                                                        constants.ENTER_ADDRESS
                                                    }
                                                    value={
                                                        values.address.street
                                                    }
                                                    onChange={handleChange(
                                                        'address.street'
                                                    )}
                                                    isInvalid={Boolean(
                                                        touched.address
                                                            ?.street &&
                                                            errors.address
                                                                ?.street
                                                    )}
                                                    disabled={loading}
                                                />
                                                <Form.Control.Feedback type="invalid">
                                                    {errors.address?.street}
                                                </Form.Control.Feedback>
                                            </Form.Group>
                                        </Col>
                                        <Col md={6}>
                                            <Form.Group controlId="reportForm.address.city">
                                                <Form.Control
                                                    type="text"
                                                    placeholder={
                                                        constants.ENTER_CITY
                                                    }
                                                    value={values.address.city}
                                                    onChange={handleChange(
                                                        'address.city'
                                                    )}
                                                    isInvalid={Boolean(
                                                        touched.address?.city &&
                                                            errors.address?.city
                                                    )}
                                                    disabled={loading}
                                                />
                                                <Form.Control.Feedback type="invalid">
                                                    {errors.address?.city}
                                                </Form.Control.Feedback>
                                            </Form.Group>
                                        </Col>
                                    </Row>
                                    <Row>
                                        <Col md={6}>
                                            {' '}
                                            <Form.Group controlId="reportForm.address.phone">
                                                <Form.Control
                                                    type="text"
                                                    placeholder={
                                                        constants.ENTER_PHONE
                                                    }
                                                    value={values.address.phone}
                                                    onChange={handleChange(
                                                        'address.phone'
                                                    )}
                                                    isInvalid={Boolean(
                                                        touched.address
                                                            ?.phone &&
                                                            errors.address
                                                                ?.phone
                                                    )}
                                                    disabled={loading}
                                                />
                                                <Form.Control.Feedback type="invalid">
                                                    {errors.address?.phone}
                                                </Form.Control.Feedback>
                                            </Form.Group>
                                        </Col>
                                        <Col md={6}>
                                            {' '}
                                            <Form.Group controlId="reportForm.address.state">
                                                <Form.Control
                                                    type="text"
                                                    placeholder={
                                                        constants.ENTER_STATE
                                                    }
                                                    value={values.address.state}
                                                    onChange={handleChange(
                                                        'address.state'
                                                    )}
                                                    isInvalid={Boolean(
                                                        touched.address
                                                            ?.state &&
                                                            errors.address
                                                                ?.state
                                                    )}
                                                    disabled={loading}
                                                />
                                                <Form.Control.Feedback type="invalid">
                                                    {errors.address?.state}
                                                </Form.Control.Feedback>
                                            </Form.Group>
                                        </Col>
                                    </Row>
                                    <Row>
                                        <Col md={6}>
                                            {' '}
                                            <Form.Group controlId="reportForm.address.postalCode">
                                                <Form.Control
                                                    type="text"
                                                    placeholder={
                                                        constants.ENTER_POSTAL_CODE
                                                    }
                                                    value={
                                                        values.address
                                                            .postalCode
                                                    }
                                                    onChange={handleChange(
                                                        'address.postalCode'
                                                    )}
                                                    isInvalid={Boolean(
                                                        touched.address
                                                            ?.postalCode &&
                                                            errors.address
                                                                ?.postalCode
                                                    )}
                                                    disabled={loading}
                                                />
                                                <Form.Control.Feedback type="invalid">
                                                    {errors.address?.postalCode}
                                                </Form.Control.Feedback>
                                            </Form.Group>
                                        </Col>
                                        <Col md={6}>
                                            {' '}
                                            <Form.Group controlId="reportForm.address.country">
                                                <Form.Control
                                                    type="text"
                                                    placeholder={
                                                        constants.ENTER_COUNTRY
                                                    }
                                                    value={
                                                        values.address.country
                                                    }
                                                    onChange={handleChange(
                                                        'address.country'
                                                    )}
                                                    isInvalid={Boolean(
                                                        touched.address
                                                            ?.country &&
                                                            errors.address
                                                                ?.country
                                                    )}
                                                    disabled={loading}
                                                />
                                                <Form.Control.Feedback type="invalid">
                                                    {errors.address?.country}
                                                </Form.Control.Feedback>
                                            </Form.Group>
                                        </Col>
                                    </Row>
                                </>
                            )}
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
                            <Form.Group controlId="reportForm.signature">
                                <Form.Control
                                    type="text"
                                    placeholder={
                                        constants.ENTER_DIGITAL_SIGNATURE
                                    }
                                    value={values.signature}
                                    onChange={handleChange('signature')}
                                    isInvalid={Boolean(
                                        touched.signature && errors.signature
                                    )}
                                    disabled={loading}
                                />
                                <Form.Control.Feedback type="invalid">
                                    {errors.signature}
                                </Form.Control.Feedback>
                            </Form.Group>

                            <Wrapper>
                                {values.reason === REPORT_REASON.COPYRIGHT && (
                                    <>
                                        <h6>
                                            {constants.JUDICIAL_DESCRIPTION()}
                                        </h6>
                                        <Form.Group controlId="formBasicCheckbox-1">
                                            <Form.Check
                                                checked={values.terms[1]}
                                                onChange={handleChange(
                                                    'terms[1]'
                                                )}
                                                isInvalid={Boolean(
                                                    touched.terms?.[1] &&
                                                        errors.terms?.[1]
                                                )}
                                                disabled={loading}
                                                type="checkbox"
                                                label={constants.TERM_1}
                                            />
                                        </Form.Group>
                                        <Form.Group controlId="formBasicCheckbox-2">
                                            <Form.Check
                                                checked={values.terms[2]}
                                                onChange={handleChange(
                                                    'terms[2]'
                                                )}
                                                isInvalid={Boolean(
                                                    touched.terms?.[2] &&
                                                        errors.terms?.[2]
                                                )}
                                                disabled={loading}
                                                type="checkbox"
                                                label={constants.TERM_2}
                                            />
                                        </Form.Group>
                                        <Form.Group controlId="formBasicCheckbox-3">
                                            <Form.Check
                                                checked={values.terms[3]}
                                                onChange={handleChange(
                                                    'terms[3]'
                                                )}
                                                isInvalid={Boolean(
                                                    touched.terms?.[3] &&
                                                        errors.terms?.[3]
                                                )}
                                                disabled={loading}
                                                type="checkbox"
                                                label={constants.TERM_3}
                                            />
                                        </Form.Group>
                                    </>
                                )}
                            </Wrapper>
                            <SubmitButton
                                buttonText={constants.SUBMIT}
                                loading={loading}
                                disabled={
                                    values.reason === REPORT_REASON.COPYRIGHT &&
                                    (!values.terms[1] ||
                                        !values.terms[2] ||
                                        !values.terms[3])
                                }
                            />
                        </Form>
                    )}
                </Formik>
            </Wrapper>
        </DialogBox>
    );
}
