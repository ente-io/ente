import React, { useState } from 'react';
import { Modal, Spinner } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import styled from 'styled-components';
import billingService, { Plan, Subscription } from 'services/billingService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import {
    convertBytesToGBs,
    getPlans,
    getUserSubscription,
    hasPaidPlan,
    isSubscribed,
    isUserRenewingPlan,
} from 'utils/billingUtil';
import PreviewProration from 'components/PreviewProration';

export const PlanIcon = styled.div<{ selected: boolean }>`
    padding-top: 20px;
    border-radius: 10%;
    height: 192px;
    width: 250px;
    border: 1px solid #404040;
    text-align: center;
    font-size: 20px;
    cursor: ${(props) => (props.selected ? 'not-allowed' : 'pointer')};
    background: ${(props) => props.selected && '#404040'};
`;

const LoaderOverlay = styled.div`
    height: 100%;
    width: 100%;
    display: flex;
    justify-content: center;
    position: absolute;
    z-index: 9;
    color: white;
    align-items: center;
`;

interface Props {
    modalView: boolean;
    closeModal: any;
    setBannerMessage;
}
function PlanSelector(props: Props) {
    const [loading, setLoading] = useState(false);
    const subscription = getUserSubscription();
    const plans = getPlans();
    const [previewProrationView, setPreviewProrationView] = useState(false);
    function closePreviewProration() {
        setPreviewProrationView(false);
    }
    const [selectedPlan, setSelectedPlan] = useState<Plan>(null);
    const selectPlan = async (plan) => {
        var bannerMessage;
        try {
            setLoading(true);
            if (hasPaidPlan(subscription)) {
                if (isUserRenewingPlan(plan, subscription)) {
                    return;
                }
                setSelectedPlan(plan);
                setPreviewProrationView(true);
            } else {
                await billingService.buySubscription(plan.stripeID);
            }
        } catch (err) {
            bannerMessage = {
                message: constants.SUBSCRIPTION_PURCHASE_FAILED,
                variant: 'danger',
            };
            props.setBannerMessage(bannerMessage);
        } finally {
            setLoading(false);
            props.closeModal();
        }
    };

    const updateSubscription = async () => {
        try {
            setPreviewProrationView(false);
            await billingService.updateSubscription(selectedPlan.stripeID);
            let bannerMessage = {
                message: constants.SUBSCRIPTION_UPDATE_SUCCESS,
                variant: 'success',
            };
            setLoading(false);
            await new Promise((resolve) =>
                setTimeout(() => resolve(null), 400)
            );
            props.setBannerMessage(bannerMessage);
        } catch (err) {
            let bannerMessage = {
                message: constants.SUBSCRIPTION_PURCHASE_FAILED,
                variant: 'danger',
            };
            props.setBannerMessage(bannerMessage);
        }
    };
    const PlanIcons: JSX.Element[] = plans?.map((plan) => (
        <PlanIcon
            key={plan.stripeID}
            onClick={() => {
                selectPlan(plan);
            }}
            selected={isUserRenewingPlan(plan, subscription)}
        >
            <div>
                <span
                    style={{
                        color: '#ECECEC',
                        fontWeight: 900,
                        fontSize: '72px',
                    }}
                >
                    {convertBytesToGBs(plan.storage, 0)}
                </span>
                <span
                    style={{
                        color: '#858585',
                        fontSize: '24px',
                        fontWeight: 900,
                    }}
                >
                    {' '}
                    GB
                </span>
            </div>
            <div
                style={{
                    color: '#ECECEC',
                    lineHeight: '24px',
                    fontSize: '24px',
                }}
            >
                {`${plan.price} / ${constants.MONTH}`}
            </div>
            {isUserRenewingPlan(plan, subscription) && 'active'}
        </PlanIcon>
    ));
    return (
        <>
            <Modal
                show={props.modalView}
                onHide={props.closeModal}
                dialogClassName="modal-90w"
                style={{ maxWidth: '100%' }}
            >
                <Modal.Header closeButton>
                    <Modal.Title style={{ marginLeft: '12px' }}>
                        {isSubscribed(subscription)
                            ? constants.MANAGE_PLAN
                            : constants.CHOOSE_PLAN}
                    </Modal.Title>
                </Modal.Header>
                <Modal.Body
                    style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        flexWrap: 'wrap',
                        minHeight: '150px',
                    }}
                >
                    {PlanIcons}
                    {(!plans || loading) && (
                        <LoaderOverlay>
                            <Spinner animation="border" />
                        </LoaderOverlay>
                    )}
                </Modal.Body>
            </Modal>
            <PreviewProration
                show={previewProrationView}
                closePreview={closePreviewProration}
                selectedPlan={selectedPlan}
                updateSubscription={updateSubscription}
            />
        </>
    );
}

export default PlanSelector;
