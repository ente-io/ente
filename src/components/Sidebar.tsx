import React, { useEffect, useState } from 'react';

import { slide as Menu } from 'react-burger-menu';
import { CONFIRM_ACTION } from 'components/ConfirmDialog';
import Spinner from 'react-bootstrap/Spinner';
import subscriptionService, {
    Subscription,
} from 'services/subscriptionService';
import constants from 'utils/strings/constants';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { getToken } from 'utils/common/key';
import { getEndpoint } from 'utils/common/apiUtil';
import exportService from 'services/exportService';
import { file } from 'services/fileService';
import isElectron from 'is-electron';
import { collection } from 'services/collectionService';
import { useRouter } from 'next/router';
import RecoveryKeyModal from './RecoveryKeyModal';
interface Props {
    files: file[];
    collections: collection[];
    setConfirmAction: any;
    somethingWentWrong: any;
}
export default function Sidebar(props: Props) {
    const [usage, SetUsage] = useState<string>(null);
    const subscription: Subscription = getData(LS_KEYS.SUBSCRIPTION);
    const [isOpen, setIsOpen] = useState(false);
    const [modalView, setModalView] = useState(false);
    useEffect(() => {
        const main = async () => {
            if (!isOpen) {
                return;
            }
            const usage = await subscriptionService.getUsage();

            SetUsage(usage);
        };
        main();
    }, [isOpen]);

    function openFeedbackURL() {
        const feedbackURL: string =
            getEndpoint() + '/users/feedback?token=' + getToken();
        var win = window.open(feedbackURL, '_blank');
        win.focus();
    }
    function exportFiles() {
        if (isElectron()) {
            exportService.exportFiles(props.files, props.collections);
        } else {
            props.setConfirmAction(CONFIRM_ACTION.DOWNLOAD_APP);
        }
    }
    const router = useRouter();

    return (
        <Menu
            isOpen={isOpen}
            onStateChange={(state) => setIsOpen(state.isOpen)}
            itemListElement="div"
        >
            <div style={{ outline: 'none' }}>
                <h5 style={{ marginBottom: '12px' }}>
                    {constants.SUBSCRIPTION_PLAN}
                </h5>
                <div style={{ color: '#959595' }}>
                    {subscription?.productID == 'free'
                        ? constants.FREE_SUBSCRIPTION_INFO(
                              subscription?.expiryTime
                          )
                        : constants.PAID_SUBSCRIPTION_INFO(
                              subscription?.expiryTime
                          )}
                </div>
            </div>
            <div style={{ outline: 'none', marginTop: '30px' }}>
                <h5 style={{ marginBottom: '12px' }}>
                    {constants.USAGE_DETAILS}
                </h5>
                <div style={{ color: '#959595' }}>
                    {usage ? (
                        constants.USAGE_INFO(
                            usage,
                            Math.ceil(
                                Number(
                                    subscriptionService.convertBytesToGBs(
                                        subscription?.storage
                                    )
                                )
                            )
                        )
                    ) : (
                        <Spinner animation="border" />
                    )}
                </div>
            </div>
            <div
                style={{
                    height: '1px',
                    marginTop: '40px',
                    background: '#242424',
                    width: '100%',
                }}
            ></div>
            <h5
                style={{ cursor: 'pointer', marginTop: '40px' }}
                onClick={openFeedbackURL}
            >
                request feature
            </h5>
            <h5 style={{ cursor: 'pointer', marginTop: '30px' }}>
                <a
                    href="mailto:contact@ente.io"
                    style={{ textDecoration: 'inherit', color: 'inherit' }}
                    target="_blank"
                    rel="noreferrer noopener"
                >
                    support
                </a>
            </h5>

            <h5
                style={{ cursor: 'pointer', marginTop: '30px' }}
                onClick={exportFiles}
            >
                {constants.EXPORT}
            </h5>
            <h5
                style={{ cursor: 'pointer', marginTop: '30px' }}
                onClick={() => router.push('changePassword')}
            >
                {constants.CHANGE_PASSWORD}
            </h5>
            <>
                <RecoveryKeyModal
                    show={modalView}
                    onHide={() => setModalView(false)}
                    somethingWentWrong={props.somethingWentWrong}
                />
                <h5
                    style={{ cursor: 'pointer', marginTop: '30px' }}
                    onClick={() => setModalView(true)}
                >
                    {constants.DOWNLOAD_RECOVERY_KEY}
                </h5>
            </>
            <h5
                style={{
                    cursor: 'pointer',
                    color: '#F96C6C',
                    marginTop: '30px',
                }}
                onClick={() => props.setConfirmAction(CONFIRM_ACTION.LOGOUT)}
            >
                logout
            </h5>
        </Menu>
    );
}
