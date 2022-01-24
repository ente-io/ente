import React, { useEffect, useState } from 'react';
import { Button } from 'react-bootstrap';
import styled from 'styled-components';
import GetDeviceOS, { OS } from 'utils/common/deviceDetection';
import constants from 'utils/strings/constants';

const Wrapper = styled.div`
    position: fixed;
    display: flex;
    align-items: center;
    justify-content: center;
    top: 0;
    z-index: 100;
    min-height: 64px;
    right: 32px;
    transition: opacity 1s ease;
    cursor: pointer;
`;

const NoStyleAnchor = styled.a`
    text-decoration: none !important;
    &:hover {
        color: #fff !important;
    }
`;

export const ButtonWithLink = ({
    href,
    children,
}: React.PropsWithChildren<{ href: string }>) => (
    <Button variant="outline-success">
        <NoStyleAnchor href={href}>{children}</NoStyleAnchor>
    </Button>
);

function GoToEnte() {
    const [os, setOS] = useState<OS>(OS.UNKNOWN);

    useEffect(() => {
        const os = GetDeviceOS();
        setOS(os);
    }, []);

    const getButtonText = (os: OS) => {
        if (os === OS.ANDROID || os === OS.IOS) {
            return constants.INSTALL;
        } else {
            return constants.SIGNUP_OR_LOGIN;
        }
    };

    const getHookLink = (os: OS) => {
        if (os === OS.ANDROID || os === OS.IOS) {
            return 'https://ente.io/app';
        } else {
            return 'https://web.ente.io';
        }
    };

    return (
        <Wrapper>
            <ButtonWithLink href={getHookLink(os)}>
                {getButtonText(os)}
            </ButtonWithLink>
        </Wrapper>
    );
}

export default GoToEnte;
