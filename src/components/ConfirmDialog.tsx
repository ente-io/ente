import React from 'react';
import constants from 'utils/strings/constants';
import MessageDialog, { MessageAttributes } from './MessageDialog';

export interface ConfirmActionAttributes {
    action: CONFIRM_ACTION;
    callback: Function;
    messageAttribute?: MessageAttributes;
}
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
function reverseString(title: string) {
    return title
        ?.split(' ')
        .reduce((reversedString, currWord) => `${currWord} ${reversedString}`);
}
interface Props {
    show: boolean;
    onHide: () => void;
    attributes: ConfirmActionAttributes;
}
function ConfirmDialog({ attributes, ...props }: Props) {
    if (attributes == null) {
        return null;
    }
    let { action, callback, messageAttribute } = attributes;
    messageAttribute = messageAttribute ?? {};
    return (
        <>
            <MessageDialog
                {...props}
                attributes={{
                    title: `${constants.CONFIRM} ${reverseString(
                        constants[CONFIRM_ACTION_VALUES[action]?.text]
                    )}`,
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
                    {messageAttribute.content ??
                        constants[
                            `${CONFIRM_ACTION_VALUES[action]?.text}_MESSAGE`
                        ]()}
                </h5>
            </MessageDialog>
        </>
    );
}
export default ConfirmDialog;
