import React, { useContext, useEffect, useState } from 'react';
import Select from 'react-select';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import Form from 'react-bootstrap/Form';
import FormControl from 'react-bootstrap/FormControl';
import { Accordion, Button, Col, Table } from 'react-bootstrap';
import { DeadCenter, GalleryContext } from 'pages/gallery';
import { User } from 'types/user';
import {
    shareCollection,
    unshareCollection,
    createShareableURL,
    deleteShareableURL,
    updateShareableURL,
} from 'services/collectionService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import SubmitButton from './SubmitButton';
import MessageDialog from './MessageDialog';
import { Collection, PublicURL, UpdatePublicURL } from 'types/collection';
import {
    appendCollectionKeyToShareURL,
    selectIntOptions,
    shareExpiryOptions,
} from 'utils/collection';
import { FlexWrapper, Label, Row, Value } from './Container';
import { CodeBlock } from './CodeBlock';
import { ButtonVariant, getVariantColor } from './pages/gallery/LinkButton';
import { handleSharingErrors } from 'utils/error';
import { sleep } from 'utils/common';
import { SelectStyles } from './Search/SelectStyle';
import CryptoWorker from 'utils/crypto';
import { dateStringWithMMH } from 'utils/time';
import styled from 'styled-components';

interface Props {
    show: boolean;
    onHide: () => void;
    collection: Collection;
    syncWithRemote: () => Promise<void>;
}
interface formValues {
    email: string;
}

interface passFormValues {
    linkPassword: string;
}
interface ShareeProps {
    sharee: User;
    collectionUnshare: (sharee: User) => void;
}

const style = {
    ...SelectStyles,
    dropdownIndicator: (style) => ({
        ...style,
        margin: '0px',
    }),
    singleValue: (style) => ({
        ...style,
        margin: '0px',
        backgroundColor: '#282828',
        color: '#d1d1d1',
        display: 'block',
        width: '120px',
    }),
    control: (style, { isFocused }) => ({
        ...style,
        minWidth: '130px',
        backgroundColor: '#282828',
        margin: '0px',
        color: '#d1d1d1',
        borderColor: isFocused ? '#51cd7c' : '#444',
        boxShadow: 'none',
        ':hover': {
            borderColor: '#51cd7c',
            cursor: 'text',
            '&>.icon': { color: '#51cd7c' },
        },
    }),
};

function CollectionShare(props: Props) {
    const [loading, setLoading] = useState(false);
    const galleryContext = useContext(GalleryContext);
    const [sharableLinkError, setSharableLinkError] = useState(null);
    const [publicShareUrl, setPublicShareUrl] = useState<string>(null);
    const [publicShareProp, setPublicShareProp] = useState<PublicURL>(null);
    const [configurePassword, setConfigurePassword] = useState(false);
    const deviceLimitOptions = selectIntOptions(50);
    const expiryOptions = shareExpiryOptions;

    useEffect(() => {
        const main = async () => {
            if (props.collection?.publicURLs?.[0]?.url) {
                const t = await appendCollectionKeyToShareURL(
                    props.collection?.publicURLs?.[0]?.url,
                    props.collection.key
                );
                setPublicShareUrl(t);
                setPublicShareProp(
                    props.collection?.publicURLs?.[0] as PublicURL
                );
            } else {
                setPublicShareUrl(null);
                setPublicShareProp(null);
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
            galleryContext.startLoading();
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
                await sleep(2000);
                await galleryContext.syncWithRemote(false, true);
                resetForm();
            }
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setFieldError('email', errorMessage);
        } finally {
            setLoading(false);
            galleryContext.finishLoading();
        }
    };
    const collectionUnshare = async (sharee) => {
        try {
            galleryContext.startLoading();
            await unshareCollection(props.collection, sharee.email);
            await sleep(2000);
            await galleryContext.syncWithRemote(false, true);
        } finally {
            galleryContext.finishLoading();
        }
    };

    const createSharableURLHelper = async () => {
        try {
            galleryContext.startLoading();
            const publicURL = await createShareableURL(props.collection);
            const sharableURL = await appendCollectionKeyToShareURL(
                publicURL.url,
                props.collection.key
            );
            setPublicShareUrl(sharableURL);
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.finishLoading();
        }
    };

    const disablePublicSharingHelper = async () => {
        try {
            galleryContext.startLoading();
            await deleteShareableURL(props.collection);
            setPublicShareUrl(null);
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.finishLoading();
        }
    };

    const savePassword = async (
        { linkPassword }: passFormValues,
        { setFieldError }: FormikHelpers<passFormValues>
    ) => {
        if (linkPassword && linkPassword.trim().length >= 1) {
            setConfigurePassword(!configurePassword);
            await enablePublicUrlPassword(linkPassword);
        } else {
            setFieldError('linkPassword', 'can not be empty');
        }
    };

    const handlePasswordChangeSetting = async () => {
        if (publicShareProp.passwordEnabled) {
            await disablePublicUrlPassword();
        } else {
            setConfigurePassword(!configurePassword);
        }
    };

    const disablePublicUrlPassword = async () => {
        return updatePublicShareURLHelper({
            collectionID: props.collection.id,
            disablePassword: true,
        });
    };

    const enablePublicUrlPassword = async (password: string) => {
        const cryptoWorker = await new CryptoWorker();
        const kekSalt: string = await cryptoWorker.generateSaltToDeriveKey();
        const kek = await cryptoWorker.deriveInteractiveKey(password, kekSalt);
        const passHash = await cryptoWorker.toB64(kek.key);
        return updatePublicShareURLHelper({
            collectionID: props.collection.id,
            passHash: passHash,
            nonce: kekSalt,
            opsLimit: kek.opsLimit,
            memLimit: kek.memLimit,
        });
    };

    const disablePublicSharing = () => {
        galleryContext.setDialogMessage({
            title: constants.DISABLE_PUBLIC_SHARING,
            content: constants.DISABLE_PUBLIC_SHARING_MESSAGE,
            close: { text: constants.CANCEL },
            proceed: {
                text: constants.DISABLE,
                action: disablePublicSharingHelper,
                variant: ButtonVariant.danger,
            },
        });
    };

    const disableFileDownload = () => {
        galleryContext.setDialogMessage({
            title: constants.DISABLE_FILE_DOWNLOAD,
            content: constants.DISABLE_FILE_DOWNLOAD_MESSAGE,
            close: { text: constants.CANCEL },
            proceed: {
                text: constants.DISABLE,
                action: () =>
                    updatePublicShareURLHelper({
                        collectionID: props.collection.id,
                        enableDownload: false,
                    }),
                variant: ButtonVariant.danger,
            },
        });
    };

    const updatePublicShareURLHelper = async (req: UpdatePublicURL) => {
        try {
            galleryContext.startLoading();
            const response = await updateShareableURL(req);
            setPublicShareProp(response);
            galleryContext.syncWithRemote(false, true);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.finishLoading();
        }
    };

    const updateDeviceLimit = async (newLimit: number) => {
        return updatePublicShareURLHelper({
            collectionID: props.collection.id,
            deviceLimit: newLimit,
        });
    };

    const updateDeviceExpiry = async (optionFn) => {
        return updatePublicShareURLHelper({
            collectionID: props.collection.id,
            validTill: optionFn(),
        });
    };

    const handleCollectionPublicSharing = () => {
        setSharableLinkError(null);
        if (publicShareUrl) {
            disablePublicSharing();
        } else {
            createSharableURLHelper();
        }
    };

    const handleFileDownloadSetting = () => {
        if (publicShareProp.enableDownload) {
            disableFileDownload();
        } else {
            updatePublicShareURLHelper({
                collectionID: props.collection.id,
                enableDownload: true,
            });
        }
    };

    const _deviceExpiryTime = (): string => {
        const validTill = publicShareProp?.validTill ?? 0;
        if (validTill === 0) {
            return 'never';
        }
        return dateStringWithMMH(validTill);
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

    const OptionLabel = styled(Label)`
        width: 70%;
        text-align: left;
    `;
    const OptionValue = styled(Value)`
        width: 30%;
    `;
    return (
        <MessageDialog
            show={props.show}
            onHide={props.onHide}
            attributes={{
                title: constants.SHARE_COLLECTION,
                staticBackdrop: true,
            }}>
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
                <div
                    style={{
                        height: '1px',
                        marginTop: '10px',
                        marginBottom: '18px',
                        background: '#444',
                        width: '100%',
                    }}
                />
                <div>
                    <FlexWrapper>
                        <FlexWrapper
                            style={{ paddingTop: '5px', color: '#fff' }}>
                            {constants.PUBLIC_SHARING}
                        </FlexWrapper>
                        <Form.Switch
                            style={{ marginLeft: '20px' }}
                            checked={!!publicShareUrl}
                            id="collection-public-sharing-toggler"
                            className="custom-switch-md"
                            onChange={handleCollectionPublicSharing}
                        />
                    </FlexWrapper>
                    {sharableLinkError && (
                        <FlexWrapper
                            style={{
                                marginTop: '10px',
                                color: getVariantColor(ButtonVariant.danger),
                            }}>
                            {sharableLinkError}
                        </FlexWrapper>
                    )}
                </div>
                {publicShareUrl ? (
                    <div style={{ width: '100%', wordBreak: 'break-all' }}>
                        <CodeBlock key={publicShareUrl} code={publicShareUrl} />

                        <Accordion
                            defaultActiveKey="0"
                            style={{ padding: '0 20px' }}>
                            <Accordion.Toggle
                                as={Button}
                                variant="link"
                                eventKey="0">
                                <h6>{constants.MANAGE_LINK}</h6>
                            </Accordion.Toggle>
                            <Accordion.Collapse eventKey="0">
                                <>
                                    <Row>
                                        <OptionLabel>
                                            {constants.LINK_DEVICE_LIMIT}
                                        </OptionLabel>
                                        <OptionValue
                                            style={{
                                                minWidth: '60px',
                                                flex: 1,
                                            }}>
                                            <Select
                                                menuPosition="fixed"
                                                options={deviceLimitOptions}
                                                isSearchable={false}
                                                placeholder={publicShareProp?.deviceLimit?.toString()}
                                                onChange={(e) =>
                                                    updateDeviceLimit(e.value)
                                                }
                                                styles={style}
                                            />
                                        </OptionValue>
                                    </Row>

                                    <Row>
                                        <OptionLabel>
                                            {constants.LINK_EXPIRY} :{' '}
                                            {_deviceExpiryTime()}{' '}
                                        </OptionLabel>
                                        <OptionValue>
                                            <Select
                                                menuPosition="fixed"
                                                options={expiryOptions}
                                                isSearchable={false}
                                                placeholder={'change'}
                                                onChange={(e) => {
                                                    updateDeviceExpiry(e.value);
                                                }}
                                                styles={style}
                                            />
                                        </OptionValue>
                                    </Row>
                                    <Row>
                                        <OptionLabel>
                                            {constants.FILE_DOWNLOAD}
                                        </OptionLabel>
                                        <OptionValue>
                                            <Form.Switch
                                                style={{ marginLeft: '10px' }}
                                                checked={
                                                    publicShareProp?.enableDownload ??
                                                    false
                                                }
                                                id="public-sharing-file-download-toggler"
                                                className="custom-switch-md"
                                                onChange={
                                                    handleFileDownloadSetting
                                                }
                                            />
                                        </OptionValue>
                                    </Row>

                                    <Row>
                                        <OptionLabel>
                                            {constants.LINK_PASSWORD_LOCK}{' '}
                                        </OptionLabel>
                                        <OptionValue>
                                            <Form.Switch
                                                style={{ marginLeft: '10px' }}
                                                checked={
                                                    (publicShareProp?.passwordEnabled ||
                                                        configurePassword) ??
                                                    false
                                                }
                                                id="public-sharing-file-password-toggler"
                                                className="custom-switch-md"
                                                onChange={
                                                    handlePasswordChangeSetting
                                                }
                                            />
                                        </OptionValue>
                                    </Row>
                                </>
                            </Accordion.Collapse>
                        </Accordion>
                        {configurePassword ? (
                            <DeadCenter
                                style={{ width: '85%', margin: '20px' }}>
                                <Formik<passFormValues>
                                    initialValues={{ linkPassword: '' }}
                                    validateOnChange={false}
                                    validateOnBlur={false}
                                    onSubmit={savePassword}>
                                    {({
                                        values,
                                        errors,
                                        touched,
                                        handleChange,
                                        handleSubmit,
                                    }) => (
                                        <Form
                                            noValidate
                                            onSubmit={handleSubmit}>
                                            <Form.Row>
                                                <Form.Group
                                                    as={Col}
                                                    xs={10}
                                                    controlId="formHorizontalPassword">
                                                    <Form.Control
                                                        type="text"
                                                        placeholder={
                                                            'link password'
                                                        }
                                                        value={
                                                            values.linkPassword
                                                        }
                                                        onChange={handleChange(
                                                            'linkPassword'
                                                        )}
                                                        autoFocus
                                                        disabled={loading}
                                                    />
                                                    <FormControl.Feedback type="invalid">
                                                        {touched.linkPassword &&
                                                            errors.linkPassword}
                                                    </FormControl.Feedback>
                                                </Form.Group>
                                                <Form.Group
                                                    as={Col}
                                                    xs={10}
                                                    controlId="formHorizontalEmail">
                                                    <SubmitButton
                                                        loading={loading}
                                                        inline
                                                        buttonText="save"
                                                    />
                                                </Form.Group>
                                            </Form.Row>
                                        </Form>
                                    )}
                                </Formik>
                            </DeadCenter>
                        ) : (
                            <div />
                        )}
                    </div>
                ) : (
                    <div style={{ height: '30px' }} />
                )}
            </DeadCenter>
        </MessageDialog>
    );
}
export default CollectionShare;
