import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import { Col, Form, FormControl } from 'react-bootstrap';
import { Value } from 'components/Container';
import CloseIcon from '@mui/icons-material/Close';
import TickIcon from '@mui/icons-material/Done';
import { Formik } from 'formik';
import * as Yup from 'yup';
import { MAX_CAPTION_SIZE } from 'constants/file';
import { SmallLoadingSpinner } from '../styledComponents/SmallLoadingSpinner';
import { IconButton } from '@mui/material';

export interface formValues {
    caption: string;
}

export const CaptionEditForm = ({ caption, saveEdits, discardEdits }) => {
    const [loading, setLoading] = useState(false);

    const onSubmit = async (values: formValues) => {
        try {
            setLoading(true);
            await saveEdits(values.caption);
        } finally {
            setLoading(false);
        }
    };
    return (
        <Formik<formValues>
            initialValues={{ caption }}
            validationSchema={Yup.object().shape({
                caption: Yup.string()
                    .required(constants.REQUIRED)
                    .max(MAX_CAPTION_SIZE, constants.CAPTION_CHARACTER_LIMIT),
            })}
            validateOnBlur={false}
            onSubmit={onSubmit}>
            {({ values, errors, handleChange, handleSubmit }) => (
                <Form noValidate onSubmit={handleSubmit}>
                    <Form.Row>
                        <Form.Group bsPrefix="ente-form-group" as={Col} xs={9}>
                            <Form.Control
                                as="textarea"
                                placeholder={constants.CAPTION}
                                value={values.caption}
                                onChange={handleChange('caption')}
                                isInvalid={Boolean(errors.caption)}
                                autoFocus
                                disabled={loading}
                            />
                            <FormControl.Feedback
                                type="invalid"
                                style={{ textAlign: 'center' }}>
                                {errors.caption}
                            </FormControl.Feedback>
                        </Form.Group>
                        <Form.Group bsPrefix="ente-form-group" as={Col} xs={3}>
                            <Value width={'16.67%'}>
                                <IconButton type="submit" disabled={loading}>
                                    {loading ? (
                                        <SmallLoadingSpinner />
                                    ) : (
                                        <TickIcon />
                                    )}
                                </IconButton>
                                <IconButton
                                    onClick={discardEdits}
                                    disabled={loading}>
                                    <CloseIcon />
                                </IconButton>
                            </Value>
                        </Form.Group>
                    </Form.Row>
                </Form>
            )}
        </Formik>
    );
};
