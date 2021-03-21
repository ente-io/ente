import React, { MouseEventHandler, useEffect, useState } from 'react';
import { Button, Modal, Spinner } from 'react-bootstrap';
import billingService, { Invoice, Plan } from 'services/billingService';
import constants from 'utils/strings/constants';

interface Props {
    show: boolean;
    closePreview;
    updateSubscription;
    selectedPlan: Plan;
}
function PreviewProration(props: Props) {
    const [upcomingInvoice, setUpcomingInvoice] = useState<Invoice>(null);

    useEffect(() => {
        if (!props.selectedPlan) {
            return;
        }
        const main = async () => {
            const invoice = await billingService.previewProration(
                props.selectedPlan.stripeID
            );
            console.log(invoice);
            setUpcomingInvoice(invoice);
        };
        main();
    }, [props.selectedPlan]);
    return (
        <Modal
            show={props.show}
            onHide={props.closePreview}
            size="lg"
            aria-labelledby="contained-modal-title-vcenter"
            centered
        >
            <Modal.Body style={{ padding: '24px' }}>
                <Modal.Title id="contained-modal-title-vcenter">
                    Proration Preview
                    <hr />
                    {upcomingInvoice ? (
                        <>
                            <li>
                                {`For ${
                                    upcomingInvoice.lines.data[0].description
                                } you get ${Math.abs(
                                    upcomingInvoice.lines.data[0].amount / 100
                                )} ${upcomingInvoice.lines.data[0].currency}`}
                            </li>
                            <li>
                                {`For ${
                                    upcomingInvoice.lines.data[1].description
                                } you are charged ${Math.abs(
                                    upcomingInvoice.lines.data[1].amount / 100
                                )} ${upcomingInvoice.lines.data[1].currency}`}
                            </li>
                            <br />
                            <div>
                                Difference Amount to be paid -{' '}
                                {(upcomingInvoice.total -
                                    upcomingInvoice.lines.data[2].amount) /
                                    100}{' '}
                                {upcomingInvoice.lines.data[1].currency}
                            </div>
                            <div>
                                {`New Purchase ${upcomingInvoice.lines.data[2].description}`}
                            </div>
                        </>
                    ) : (
                        <Spinner animation="border" />
                    )}
                </Modal.Title>
            </Modal.Body>
            <Modal.Footer style={{ borderTop: 'none' }}>
                <Button variant="secondary" onClick={props.closePreview}>
                    {constants.CLOSE}
                </Button>
                <Button variant="primary" onClick={props.updateSubscription}>
                    Update
                </Button>
            </Modal.Footer>
        </Modal>
    );
}
export default PreviewProration;
