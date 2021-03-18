import { BannerMessage } from 'pages/_app';
import React, { MouseEventHandler } from 'react';
import { Alert, Button, CloseButton, Modal } from 'react-bootstrap';
import constants from 'utils/strings/constants';

interface Props {
    bannerMessage: BannerMessage;
    onHide: MouseEventHandler<HTMLElement>;
}
function MessageDialog(props: Props) {
    return (
        <Modal
            show={props.bannerMessage != null}
            onHide={props.onHide}
            size="lg"
            aria-labelledby="contained-modal-title-vcenter"
            centered
            animation={true}
        >
            <Modal.Title>
                <Alert
                    variant={props.bannerMessage?.variant}
                    style={{
                        textAlign: 'center',
                        height: '80px',
                        lineHeight: '50px',
                        fontSize: '1.3em',
                        margin: 0,
                    }}
                >
                    {props.bannerMessage?.message}
                    <CloseButton onClick={props.onHide} />
                </Alert>
            </Modal.Title>
        </Modal>
    );
}
export default MessageDialog;
