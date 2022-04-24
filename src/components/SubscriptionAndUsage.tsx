import React from 'react';
import { Button } from 'react-bootstrap';
import { Subscription } from 'types/billing';
import { User } from 'types/user';
import {
    isSubscriptionActive,
    isOnFreePlan,
    isSubscriptionCancelled,
    isSubscribed,
    convertBytesToHumanReadable,
} from 'utils/billing';
import constants from 'utils/strings/constants';
import EnteSpinner from './EnteSpinner';

interface Iprops {
    user: User;
    subscription: Subscription;
}
export default function SubscriptionAndUsage(props: Iprops) {
    const { user, subscription } = props;
    return (
        <div
            style={{
                flex: 1,
                overflow: 'auto',
                outline: 'none',
                paddingTop: '0',
            }}>
            <div style={{ outline: 'none' }}>
                <div style={{ display: 'flex' }}>
                    <h5 style={{ margin: '4px 0 12px 2px' }}>
                        {constants.SUBSCRIPTION_PLAN}
                    </h5>
                </div>
                <div style={{ color: '#959595' }}>
                    {isSubscriptionActive(subscription) ? (
                        isOnFreePlan(subscription) ? (
                            constants.FREE_SUBSCRIPTION_INFO(
                                subscription?.expiryTime
                            )
                        ) : isSubscriptionCancelled(subscription) ? (
                            constants.RENEWAL_CANCELLED_SUBSCRIPTION_INFO(
                                subscription?.expiryTime
                            )
                        ) : (
                            constants.RENEWAL_ACTIVE_SUBSCRIPTION_INFO(
                                subscription?.expiryTime
                            )
                        )
                    ) : (
                        <p>{constants.SUBSCRIPTION_EXPIRED}</p>
                    )}
                    <Button
                        variant="outline-success"
                        block
                        size="sm"
                        onClick={() => null}>
                        {isSubscribed(subscription)
                            ? constants.MANAGE
                            : constants.SUBSCRIBE}
                    </Button>
                </div>
            </div>
            <div style={{ outline: 'none', marginTop: '30px' }} />
            <div>
                <h5 style={{ marginBottom: '12px' }}>
                    {constants.USAGE_DETAILS}
                </h5>
                <div style={{ color: '#959595' }}>
                    {user?.usage ? (
                        constants.USAGE_INFO(
                            user.usage,
                            convertBytesToHumanReadable(subscription?.storage)
                        )
                    ) : (
                        <div style={{ textAlign: 'center' }}>
                            <EnteSpinner
                                style={{
                                    borderWidth: '2px',
                                    width: '20px',
                                    height: '20px',
                                }}
                            />
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
