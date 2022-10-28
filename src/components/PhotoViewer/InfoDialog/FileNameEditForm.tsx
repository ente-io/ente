import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import { Col, Form, FormControl } from 'react-bootstrap';
import { FlexWrapper, Value } from 'components/Container';
import CloseIcon from '@mui/icons-material/Close';
import TickIcon from '@mui/icons-material/Done';
import { Formik } from 'formik';
import * as Yup from 'yup';
import { MAX_EDITED_FILE_NAME_LENGTH } from 'constants/file';
import { SmallLoadingSpinner } from '../styledComponents/SmallLoadingSpinner';
import { IconButton } from '@mui/material';

export interface formValues {
    filename: string;
}

export const FileNameEditForm = ({
    filename,
    saveEdits,
    discardEdits,
    extension,
}) => {
    const [loading, setLoading] = useState(false);

    const onSubmit = async (values: formValues) => {
        try {
            setLoading(true);
            await saveEdits(values.filename);
        } finally {
            setLoading(false);
        }
    };
    return (
        <Formik<formValues>
            initialValues={{ filename }}
            validationSchema={Yup.object().shape({
                filename: Yup.string()
                    .required(constants.REQUIRED)
                    .max(
                        MAX_EDITED_FILE_NAME_LENGTH,
                        constants.FILE_NAME_CHARACTER_LIMIT
                    ),
            })}
            validateOnBlur={false}
            onSubmit={onSubmit}>
            {({ values, errors, handleChange, handleSubmit }) => (
                <Form noValidate onSubmit={handleSubmit}>
                    <Form.Row>
                        <Form.Group
                            bsPrefix="ente-form-group"
                            as={Col}
                            xs={extension ? 8 : 9}>
                            <Form.Control
                                as="textarea"
                                placeholder={constants.FILE_NAME}
                                value={values.filename}
                                onChange={handleChange('filename')}
                                isInvalid={Boolean(errors.filename)}
                                autoFocus
                                disabled={loading}
                            />
                            <FormControl.Feedback
                                type="invalid"
                                style={{ textAlign: 'center' }}>
                                {errors.filename}
                            </FormControl.Feedback>
                        </Form.Group>
                        {extension && (
                            <Form.Group
                                bsPrefix="ente-form-group"
                                as={Col}
                                xs={1}
                                controlId="formHorizontalFileName">
                                <FlexWrapper style={{ padding: '5px' }}>
                                    {`.${extension}`}
                                </FlexWrapper>
                            </Form.Group>
                        )}
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
