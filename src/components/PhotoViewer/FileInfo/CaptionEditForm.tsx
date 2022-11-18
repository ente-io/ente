import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import { Col, Form, FormControl } from 'react-bootstrap';
import { Formik } from 'formik';
import * as Yup from 'yup';
import { MAX_CAPTION_SIZE } from 'constants/file';

export interface formValues {
    caption: string;
}

export const CaptionEditForm = ({ isInEditMode, caption, saveEdits }) => {
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
                caption: Yup.string().max(
                    MAX_CAPTION_SIZE,
                    constants.CAPTION_CHARACTER_LIMIT
                ),
            })}
            validateOnBlur={false}
            onSubmit={onSubmit}>
            {({ values, errors, handleChange, handleSubmit }) => (
                <Form noValidate onSubmit={handleSubmit}>
                    <Form.Row>
                        <Form.Group bsPrefix="ente-form-group" as={Col} xs={12}>
                            <Form.Control
                                as="textarea"
                                placeholder={constants.CAPTION_PLACEHOLDER}
                                value={values.caption}
                                onChange={handleChange('caption')}
                                isInvalid={Boolean(errors.caption)}
                                autoFocus
                                disabled={loading || !isInEditMode}
                            />
                            <FormControl.Feedback
                                type="invalid"
                                style={{ textAlign: 'center' }}>
                                {errors.caption}
                            </FormControl.Feedback>
                        </Form.Group>
                    </Form.Row>
                </Form>
            )}
        </Formik>
    );
};
