import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import Form from 'react-bootstrap/Form';
import FormControl from 'react-bootstrap/FormControl';
import { Button, Col, Table } from 'react-bootstrap';
import { DeadCenter } from 'pages/gallery';
import SubmitButton from './SubmitButton';
import { User } from 'services/userService';

interface Props {
    show: boolean;
    onHide: () => void;
    sharees: User[];
}
interface formValues {
    email: string;
}
interface ShareeProps {
    sharee: User;
}

function CollectionShare({ ...props }: Props) {
    const [loading, setLoading] = useState(false);
    const loginUser = async (
        { email }: formValues,
        { setFieldError }: FormikHelpers<formValues>
    ) => {
        try {
            setLoading(true);
            // await getOtt(email);
        } catch (e) {
            setFieldError('email', `${constants.UNKNOWN_ERROR} ${e.message}`);
        }
        setLoading(false);
    };

    const ShareeRow = ({ sharee }: ShareeProps) => (
        <tr>
            <td>
                <span style={{ marginRight: '10px' }}>{sharee.email}</span>
            </td>
            <td>
                <Button
                    variant="outline-danger"
                    style={{
                        height: '22px',
                        lineHeight: '11px',
                        padding: 0,
                        width: '22px',
                        fontSize: '30px',
                    }}
                    onClick={() => {
                        /* unshare(user)*/
                        return null;
                    }}
                >
                    -
                </Button>
            </td>
        </tr>
    );
    return (
        <MessageDialog
            size={null}
            show={props.show}
            onHide={props.onHide}
            attributes={{ title: constants.COLLECTION_SHARE }}
        >
            <DeadCenter>
                <p>{constants.SHARE_WITH_PEOPLE}</p>
                <Formik<formValues>
                    initialValues={{ email: '' }}
                    validationSchema={Yup.object().shape({
                        email: Yup.string()
                            .email(constants.EMAIL_ERROR)
                            .required(constants.REQUIRED),
                    })}
                    onSubmit={loginUser}
                >
                    {({
                        values,
                        errors,
                        touched,
                        handleChange,
                        handleBlur,
                        handleSubmit,
                    }) => (
                        <Form noValidate onSubmit={handleSubmit}>
                            <Form.Row>
                                <Form.Group
                                    as={Col}
                                    controlId="formHorizontalEmail"
                                >
                                    <Form.Control
                                        type="email"
                                        placeholder={constants.ENTER_EMAIL}
                                        value={values.email}
                                        onChange={handleChange('email')}
                                        onBlur={handleBlur('email')}
                                        isInvalid={Boolean(
                                            touched.email && errors.email
                                        )}
                                        autoFocus={true}
                                        disabled={loading}
                                    />
                                    <FormControl.Feedback type="invalid">
                                        {errors.email}
                                    </FormControl.Feedback>
                                </Form.Group>
                                <Form.Group
                                    as={Col}
                                    sm={1}
                                    controlId="formHorizontalEmail"
                                >
                                    <SubmitButton
                                        loading={loading}
                                        inline
                                        buttonText={'+'}
                                    />
                                </Form.Group>
                            </Form.Row>
                        </Form>
                    )}
                </Formik>
                <div
                    style={{
                        height: '1px',
                        margin: '10px 0px',
                        background: '#444',
                        width: '100%',
                    }}
                ></div>
                {props.sharees?.length > 0 ? (
                    <>
                        <p>{constants.SHAREES}</p>

                        <Table striped bordered hover variant="dark" size="sm">
                            <tbody>
                                {props.sharees?.map((sharee) => (
                                    <ShareeRow sharee={sharee} />
                                ))}
                            </tbody>
                        </Table>
                    </>
                ) : (
                    <p>{constants.ZERO_SHAREES()}</p>
                )}
            </DeadCenter>
        </MessageDialog>
    );
}
export default CollectionShare;
