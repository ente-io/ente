import React, { useState } from 'react';
import { Card } from 'react-bootstrap';
import styled from 'styled-components';
import CreateCollection from './CreateCollection';
import DropzoneWrapper from './DropzoneWrapper';
import constants from 'utils/strings/constants';

const ImageContainer = styled.div`
    min-height: 192px;
    max-width: 192px;
    border: 1px solid #555;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 42px;
`;

const StyledCard = styled(Card)`
    border-radius: 30px !important;
    cursor: pointer;
`;

export default function AddCollection(props) {
    const [acceptedFiles, setAcceptedFiles] = useState<File[]>();
    const [createCollectionView, setCreateCollectionView] = useState(false);

    const { closeUploadModal, showUploadModal, ...rest } = props;

    const createCollection = (acceptedFiles) => {
        setAcceptedFiles(acceptedFiles);
        setCreateCollectionView(true);
    };
    const children = (
        <StyledCard>
            <ImageContainer>+</ImageContainer>
            <Card.Text style={{ textAlign: 'center' }}>
                {constants.CREATE_COLLECTION}
            </Card.Text>
        </StyledCard>
    );
    return (
        <div style={{ margin: '10px' }}>
            <DropzoneWrapper
                onDropAccepted={createCollection}
                onDragOver={showUploadModal}
                children={children}
            />
            <CreateCollection
                {...rest}
                modalView={createCollectionView}
                closeUploadModal={closeUploadModal}
                closeModal={() => setCreateCollectionView(false)}
                acceptedFiles={acceptedFiles}
            />
        </div>
    );
}
