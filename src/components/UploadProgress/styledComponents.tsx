import {
    getVariantColor,
    ButtonVariant,
} from 'components/pages/gallery/LinkButton';
import styled from 'styled-components';

export const SectionTitle = styled.div`
    display: flex;
    justify-content: space-between;
    color: #eee;
    font-size: 20px;
    cursor: pointer;
`;

export const Section = styled.div`
    margin: 20px 0;
    padding: 0 20px;
`;
export const SectionInfo = styled.div`
    margin: 4px 0;
    padding-left: 15px;
`;

export const SectionContent = styled.div`
    padding-right: 35px;
`;

export const NotUploadSectionHeader = styled.div`
    margin-top: 30px;
    text-align: center;
    color: ${getVariantColor(ButtonVariant.warning)};
    border-bottom: 1px solid ${getVariantColor(ButtonVariant.warning)};
    margin: 0 20px;
`;

export const InProgressItemContainer = styled.div`
    display: inline-block;
    & > span {
        display: inline-block;
    }
    & > span:first-of-type {
        position: relative;
        top: 5px;
        max-width: 287px;
        overflow: hidden;
        white-space: nowrap;
        text-overflow: ellipsis;
    }
    & > .separator {
        margin: 0 5px;
    }
`;

export const ResultItemContainer = styled.div`
    position: relative;
    top: 5px;
    display: inline-block;
    max-width: 334px;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
`;
