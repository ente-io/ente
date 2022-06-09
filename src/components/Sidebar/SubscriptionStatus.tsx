import React from 'react';

export default function SubscriptionStatus() {
    return <div>SubscriptionStatus</div>;

    {
        // const { setDialogMessage } = useContext(AppContext);
        // async function onLeaveFamilyClick() {
        //     try {
        //         await billingService.leaveFamily();
        //         closeSidebar();
        //     } catch (e) {
        //         setDialogMessage({
        //             title: constants.ERROR,
        //             close: { variant: 'danger' },
        //             content: constants.UNKNOWN_ERROR,
        //         });
        //     }
        // }
        /* {!hasNonAdminFamilyMembers(userDetails.familyData) ||
        isFamilyAdmin(userDetails.familyData) ? (
            <div style={{ color: '#959595' }}>
                {isSubscriptionActive(userDetails.subscription) ? (
                    isOnFreePlan(userDetails.subscription) ? (
                        constants.FREE_SUBSCRIPTION_INFO(
                            userDetails.subscription?.expiryTime
                        )
                    ) : isSubscriptionCancelled(
                          userDetails.subscription
                      ) ? (
                        constants.RENEWAL_CANCELLED_SUBSCRIPTION_INFO(
                            userDetails.subscription?.expiryTime
                        )
                    ) : (
                        constants.RENEWAL_ACTIVE_SUBSCRIPTION_INFO(
                            userDetails.subscription?.expiryTime
                        )
                    )
                ) : (
                    <p>{constants.SUBSCRIPTION_EXPIRED(onManageClick)}</p>
                )}
                <Button onClick={onManageClick}>
                    {isSubscribed(userDetails.subscription)
                        ? constants.MANAGE
                        : constants.SUBSCRIBE}
                </Button>
            </div>
        ) : (
            <div style={{ color: '#959595' }}>
                {constants.FAMILY_PLAN_MANAGE_ADMIN_ONLY(
                    getFamilyPlanAdmin(userDetails.familyData)?.email
                )}
                <Button
                    onClick={() =>
                        setDialogMessage({
                            title: `${constants.LEAVE_FAMILY}`,
                            content: constants.LEAVE_FAMILY_CONFIRM,
                            staticBackdrop: true,
                            proceed: {
                                text: constants.LEAVE_FAMILY,
                                action: onLeaveFamilyClick,
                                variant: 'danger',
                            },
                            close: { text: constants.CANCEL },
                        })
                    }>
                    {constants.LEAVE_FAMILY}
                </Button>
            </div>
        )}

        {hasNonAdminFamilyMembers(userDetails.familyData)
            ? constants.FAMILY_USAGE_INFO(
                  userDetails.usage,
                  convertBytesToHumanReadable(
                      getStorage(userDetails.familyData)
                  )
              )
            : constants.USAGE_INFO(
                  userDetails.usage,
                  convertBytesToHumanReadable(
                      userDetails.subscription?.storage
                  )
              )} */
    }
}
