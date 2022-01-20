import React, { useContext, useState } from 'react';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import Form from 'react-bootstrap/Form';
import FormControl from 'react-bootstrap/FormControl';
import { Button, Col, Row, Table } from 'react-bootstrap';
import { DeadCenter, GalleryContext } from 'pages/gallery';
import { User } from 'types/user';
import {
    shareCollection,
    unshareCollection,
    createShareableURL,
    deleteShareableURL,
} from 'services/collectionService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import SubmitButton from './SubmitButton';
import MessageDialog from './MessageDialog';
import { Collection } from 'types/collection';
import { transformShareURLForHost } from 'utils/collection';
import CopyIcon from './icons/CopyIcon';
import { IconButton, Value } from './Container';

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

    const galleryContext = useContext(GalleryContext);
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

    const createSharableURLHelper = async () => {
        const publicURL = await createShareableURL(props.collection);
        props.collection.publicURLs = [publicURL];
        await props.syncWithRemote();
    };

    const deleteSharableURLHelper = async () => {
        await deleteShareableURL(props.collection);
        await props.syncWithRemote();
    };

    const deleteSharableLink = () => {
        galleryContext.setDialogMessage({
            title: 'delete sharable url',
            content: 'are you sure you want to delete the sharable url?',
            close: { text: constants.CANCEL },
            proceed: {
                text: 'delete',
                action: deleteSharableURLHelper,
                variant: 'danger',
            },
        });
    };

    const handleCollectionPublicSharing = () => {
        if (props.collection.publicURLs?.length > 0) {
            deleteSharableLink();
        } else {
            createSharableURLHelper();
        }
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
                    onClick={() => collectionUnshare(sharee)}>
                    -
                </Button>
            </td>
        </tr>
    );
    if (!props.collection) {
        return <></>;
    }
    return (
        <MessageDialog
            show={true}
            onHide={props.onHide}
            attributes={{ title: constants.SHARE_COLLECTION }}>
            <DeadCenter style={{ width: '85%', margin: 'auto' }}>
                <h6 style={{ marginTop: '8px' }}>
                    {constants.SHARE_WITH_PEOPLE}
                </h6>
                <p />
                <Formik<formValues>
                    initialValues={{ email: '' }}
                    validationSchema={Yup.object().shape({
                        email: Yup.string()
                            .email(constants.EMAIL_ERROR)
                            .required(constants.REQUIRED),
                    })}
                    validateOnChange={false}
                    validateOnBlur={false}
                    onSubmit={collectionShare}>
                    {({
                        values,
                        errors,
                        touched,
                        handleChange,
                        handleSubmit,
                    }) => (
                        <Form noValidate onSubmit={handleSubmit}>
                            <Form.Row>
                                <Form.Group
                                    as={Col}
                                    xs={10}
                                    controlId="formHorizontalEmail">
                                    <Form.Control
                                        type="email"
                                        placeholder={constants.ENTER_EMAIL}
                                        value={values.email}
                                        onChange={handleChange('email')}
                                        isInvalid={Boolean(
                                            touched.email && errors.email
                                        )}
                                        autoFocus
                                        disabled={loading}
                                    />
                                    <FormControl.Feedback type="invalid">
                                        {errors.email}
                                    </FormControl.Feedback>
                                </Form.Group>
                                <Form.Group
                                    as={Col}
                                    xs={2}
                                    controlId="formHorizontalEmail">
                                    <SubmitButton
                                        loading={loading}
                                        inline
                                        buttonText="+"
                                    />
                                </Form.Group>
                            </Form.Row>
                        </Form>
                    )}
                </Formik>
                <Row style={{ padding: '10px' }}>
                    <Value width="100%" style={{ paddingTop: '10px' }}>
                        Public sharing
                    </Value>
                    <Form.Switch
                        style={{ marginLeft: '20px' }}
                        checked={props.collection.publicURLs?.length > 0}
                        id="collection-public-sharing-toggler"
                        className="custom-switch-md"
                        onChange={handleCollectionPublicSharing}
                    />
                </Row>
                <div
                    style={{
                        height: '1px',
                        margin: '10px 0px',
                        background: '#444',
                        width: '100%',
                    }}
                />

                {props.collection.publicURLs?.length > 0 && (
                    <div style={{ width: '100%', wordBreak: 'break-all' }}>
                        <p>{constants.PUBLIC_URL}</p>

                        {props.collection.publicURLs?.map((publicURL) => (
                            <Row key={publicURL.url}>
                                <Value width="85%">
                                    {
                                        <a
                                            href={transformShareURLForHost(
                                                publicURL.url,
                                                props.collection.key
                                            )}
                                            target="_blank"
                                            rel="noreferrer">
                                            {transformShareURLForHost(
                                                publicURL.url,
                                                props.collection.key
                                            )}
                                        </a>
                                    }
                                </Value>
                                <Value
                                    width="15%"
                                    style={{ justifyContent: 'space-around' }}>
                                    <IconButton>
                                        <CopyIcon />
                                    </IconButton>
                                </Value>
                            </Row>
                        ))}
                    </div>
                )}
                {props.collection.sharees?.length > 0 && (
                    <>
                        <p>{constants.SHAREES}</p>

                        <Table striped bordered hover variant="dark" size="sm">
                            <tbody>
                                {props.collection.sharees?.map((sharee) => (
                                    <ShareeRow
                                        key={sharee.email}
                                        sharee={sharee}
                                        collectionUnshare={collectionUnshare}
                                    />
                                ))}
                            </tbody>
                        </Table>
                    </>
                )}
                {props.collection.sharees?.length > 0 &&
                    props.collection.publicURLs?.length > 0 && (
                        <div style={{ marginTop: '12px' }}>
                            {constants.ZERO_SHAREES()}
                        </div>
                    )}
            </DeadCenter>
        </MessageDialog>
    );
}
export default CollectionShare;
