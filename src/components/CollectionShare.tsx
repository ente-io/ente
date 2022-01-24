import React, { useContext, useEffect, useState } from 'react';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import Form from 'react-bootstrap/Form';
import FormControl from 'react-bootstrap/FormControl';
import { Button, Col, Table } from 'react-bootstrap';
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
import { appendCollectionKeyToShareURL } from 'utils/collection';
import { Row, Value } from './Container';
import { CodeBlock } from './CodeBlock';
import { ButtonVariant, getVariantColor } from './pages/gallery/LinkButton';
import { handleSharingErrors } from 'utils/error';

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
    const [sharableLinkError, setSharableLinkError] = useState(null);
    const [publicShareUrl, setPublicShareUrl] = useState<string>(null);

    useEffect(() => {
        const main = async () => {
            if (props.collection?.publicURLs?.[0]?.url) {
                const t = await appendCollectionKeyToShareURL(
                    props.collection?.publicURLs?.[0]?.url,
                    props.collection.key
                );
                setPublicShareUrl(t);
            }
        };
        main();
    }, [props.collection]);

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
                props.collection?.sharees?.find(
                    (value) => value.email === email
                )
            ) {
                setFieldError('email', constants.ALREADY_SHARED(email));
            } else {
                await shareCollection(props.collection, email);
                await props.syncWithRemote();
                resetForm();
            }
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
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
        try {
            galleryContext.startLoading();
            const publicURL = await createShareableURL(props.collection);
            const sharableURL = await appendCollectionKeyToShareURL(
                publicURL.url,
                props.collection.key
            );
            galleryContext.finishLoading();
            setPublicShareUrl(sharableURL);
            await galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.finishLoading();
        }
    };

    const deleteSharableURLHelper = async () => {
        try {
            await deleteShareableURL(props.collection);
            setPublicShareUrl(null);
            await galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.finishLoading();
        }
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
        setSharableLinkError(null);
        if (publicShareUrl) {
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
            show={props.show}
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
                <Row style={{ margin: '10px' }}>
                    <Value width="auto" style={{ paddingTop: '5px' }}>
                        {constants.PUBLIC_SHARING}
                    </Value>
                    <Form.Switch
                        style={{ marginLeft: '20px' }}
                        checked={!!publicShareUrl}
                        id="collection-public-sharing-toggler"
                        className="custom-switch-md"
                        onChange={handleCollectionPublicSharing}
                    />
                </Row>
                <Row
                    style={{
                        margin: '10px',
                        color: getVariantColor(ButtonVariant.danger),
                    }}>
                    {sharableLinkError}
                </Row>
                <div
                    style={{
                        height: '1px',
                        margin: '10px 0px',
                        background: '#444',
                        width: '100%',
                    }}
                />

                {publicShareUrl && (
                    <div style={{ width: '100%', wordBreak: 'break-all' }}>
                        <>{constants.PUBLIC_URL}</>
                        <CodeBlock key={publicShareUrl} code={publicShareUrl} />
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
                {props.collection.sharees?.length === 0 && !publicShareUrl && (
                    <div style={{ marginTop: '12px' }}>
                        {constants.ZERO_SHAREES()}
                    </div>
                )}
            </DeadCenter>
        </MessageDialog>
    );
}
export default CollectionShare;
