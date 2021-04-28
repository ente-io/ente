import React, { useEffect, useState } from 'react';
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
import {
    Collection,
    shareCollection,
    unshareCollection,
} from 'services/collectionService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';

interface Props {
    show: boolean;
    onHide: () => void;
    collection: Collection;
    syncWithRemote: () => Promise<void>;
}
interface formValues {
    email: string;
}
interface ShareeProps {
    sharee: User;
    collectionUnshare: (sharee: User) => void;
}

function CollectionShare(props: Props) {
    const [loading, setLoading] = useState(false);
    const collectionShare = async (
        { email }: formValues,
        { resetForm, setFieldError }: FormikHelpers<formValues>
    ) => {
        try {
            setLoading(true);
            const user: User = getData(LS_KEYS.USER);
            if (email === user.email) {
                setFieldError('email', constants.SHARE_WITH_SELF);
            } else if (
                props.collection.sharees.find((value) => value.email === email)
            ) {
                setFieldError('email', constants.ALREADY_SHARED(email));
            } else {
                await shareCollection(props.collection, email);
                await props.syncWithRemote();
                resetForm();
            }
        } catch (e) {
            let errorMessage = null;
            switch (e?.status) {
                case 400:
                    errorMessage = constants.SHARING_BAD_REQUEST_ERROR;
                    break;
                case 402:
                    errorMessage = constants.SHARING_DISABLED_FOR_FREE_ACCOUNTS;
                    break;
                case 404:
                    errorMessage = constants.USER_DOES_NOT_EXIST;
                    break;
                default:
                    errorMessage = `${constants.UNKNOWN_ERROR} ${e.message}`;
            }
            setFieldError('email', errorMessage);
        } finally {
            setLoading(false);
        }
    };
    const collectionUnshare = async (sharee) => {
        await unshareCollection(props.collection, sharee.email);
        await props.syncWithRemote();
    };

    const ShareeRow = ({ sharee, collectionUnshare }: ShareeProps) => (
        <tr>
            <td>{sharee.email}</td>
            <td>
                <Button
                    variant="outline-danger"
                    style={{
                        height: '25px',
                        lineHeight: 0,
                        padding: 0,
                        width: '25px',
                        fontSize: '1.2em',
                        fontWeight: 900,
                    }}
                    onClick={() => collectionUnshare(sharee)}
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
            attributes={{ title: constants.SHARE_COLLECTION }}
        >
            <DeadCenter style={{ width: '85%', margin: 'auto' }}>
                <p>{constants.SHARE_WITH_PEOPLE}</p>
                <Formik<formValues>
                    initialValues={{ email: '' }}
                    validationSchema={Yup.object().shape({
                        email: Yup.string()
                            .email(constants.EMAIL_ERROR)
                            .required(constants.REQUIRED),
                    })}
                    onSubmit={collectionShare}
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
                                    xs={10}
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
                                    xs={2}
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
                {props.collection?.sharees.length > 0 ? (
                    <>
                        <p>{constants.SHAREES}</p>

                        <Table striped bordered hover variant="dark" size="sm">
                            <tbody>
                                {props.collection?.sharees.map((sharee) => (
                                    <ShareeRow
                                        key={sharee.email}
                                        sharee={sharee}
                                        collectionUnshare={collectionUnshare}
                                    />
                                ))}
                            </tbody>
                        </Table>
                    </>
                ) : (
                    <div style={{ marginTop: '12px' }}>
                        {constants.ZERO_SHAREES()}
                    </div>
                )}
            </DeadCenter>
        </MessageDialog>
    );
}
export default CollectionShare;
