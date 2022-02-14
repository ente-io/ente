import React, { useEffect, useState } from 'react';
import { Toast } from 'react-bootstrap';
import styled from 'styled-components';
import { NotificationAttributes } from 'types/gallery';

const Wrapper = styled.div`
    position: absolute;
    top: 60px;
    right: 10px;
    z-index: 1501;
    min-height: 100px;
`;
const AUTO_HIDE_TIME_IN_MILLISECONDS = 3000;

interface Iprops {
    attributes: NotificationAttributes;
    clearAttributes: () => void;
}

export default function Notification({ attributes, clearAttributes }: Iprops) {
    const [show, setShow] = useState(false);
    const closeToast = () => {
        setShow(false);
        clearAttributes();
    };
    useEffect(() => {
        if (!attributes) {
            setShow(false);
        } else {
            setShow(true);
        }
    }, [attributes]);
    return (
        <Wrapper>
            <Toast
                onClose={closeToast}
                show={show}
                delay={AUTO_HIDE_TIME_IN_MILLISECONDS}
                autohide>
                {attributes?.title && (
                    <Toast.Header
                        style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                        }}>
                        <h6 style={{ marginBottom: 0 }}>{attributes.title} </h6>
                    </Toast.Header>
                )}
                {attributes?.message && (
                    <Toast.Body>{attributes.message}</Toast.Body>
                )}
            </Toast>
        </Wrapper>
    );
}
