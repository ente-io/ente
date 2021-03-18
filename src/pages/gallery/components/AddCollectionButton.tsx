import React, { useEffect, useRef, useState } from 'react';
import { Button, Card, Form, Modal } from 'react-bootstrap';
import styled from 'styled-components';
import constants from 'utils/strings/constants';
import { CollectionIcon } from './CollectionSelector';

const ImageContainer = styled.div`
    min-height: 192px;
    max-width: 192px;
    border: 1px solid #555;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 42px;
`;

export default function AddCollectionButton({ showChoiceModal }) {
    return (
        <CollectionIcon style={{ margin: '10px' }} onClick={showChoiceModal}>
            <Card>
                <ImageContainer>+</ImageContainer>
                <Card.Text style={{ textAlign: 'center' }}>
                    {constants.CREATE_COLLECTION}
                </Card.Text>
            </Card>
        </CollectionIcon>
    );
}
