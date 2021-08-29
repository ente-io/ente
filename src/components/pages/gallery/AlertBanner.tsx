import { FlexWrapper } from 'components/Container';
import WarningIcon from 'components/icons/WarningIcon';
import React from 'react';
import styled from 'styled-components';

interface Props {
    bannerMessage?: any;
    variant?: string;
    children?: any;
    style?: any;
}
const Banner = styled.div`
    border: 1px solid yellow;
    border-radius: 8px;
    padding: 16px 28px;
    color: #eee;
    margin-top: 10px;
`;
export default function AlertBanner(props: Props) {
    return props.bannerMessage || props.children ? (
        <FlexWrapper>
            <Banner>
                <WarningIcon />
                {props.bannerMessage}
            </Banner>
        </FlexWrapper>
    ) : (
        <></>
    );
}
