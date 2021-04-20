import React from 'react';
import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';

export enum CONFIRM_ACTION {
    LOGOUT,
    DELETE,
    SESSION_EXPIRED,
    DOWNLOAD_APP,
    CANCEL_SUBSCRIPTION,
    ACTIVATE_SUBSCRIPTION,
    UPDATE_SUBSCRIPTION,
    UPDATE_PAYMENT_METHOD,
}

const CONFIRM_ACTION_VALUES = [
    { text: 'LOGOUT', type: 'danger' },
    { text: 'DELETE', type: 'danger' },
    { text: 'SESSION_EXPIRED', type: 'primary' },
    { text: 'DOWNLOAD_APP', type: 'success' },
    { text: 'CANCEL_SUBSCRIPTION', type: 'danger' },
    { text: 'ACTIVATE_SUBSCRIPTION', type: 'success' },
    { text: 'UPDATE_SUBSCRIPTION', type: 'success' },
    { text: 'UPDATE_PAYMENT_METHOD', type: 'primary' },
];
function inverseButtonType(type) {
    if (type === 'success') return 'danger';
    else {
        return 'secondary';
    }
}
function beautifyTitle(title: string) {
    return title.replaceAll('_', ' ').toLocaleLowerCase();
}

interface Props {
    callback: any;
    action: CONFIRM_ACTION;
    show: boolean;
    onHide: () => void;
}
function ConfirmDialog({ callback, action, ...props }: Props) {
    if (action == null) {
        return null;
    }
    return (
        <>
            <MessageDialog
                {...props}
                attributes={{
                    title: beautifyTitle(
                        `${constants.CONFIRM} ${
                            constants[CONFIRM_ACTION_VALUES[action]?.text]
                        }`
                    ),
                    proceed: {
                        text: constants[CONFIRM_ACTION_VALUES[action]?.text],
                        action: async () => {
                            await callback();
                            props.onHide();
                        },
                        variant: CONFIRM_ACTION_VALUES[action]?.type,
                    },
                    close: action !== CONFIRM_ACTION.SESSION_EXPIRED && {
                        text: constants.CANCEL,
                        variant: inverseButtonType(
                            CONFIRM_ACTION_VALUES[action]?.type
                        ),
                    },
                    staticBackdrop: true,
                }}
            >
                <h5>
                    {
                        constants[
                            `${CONFIRM_ACTION_VALUES[action]?.text}_MESSAGE`
                        ]
                    }
                </h5>
            </MessageDialog>
        </>
    );
}
export default ConfirmDialog;
