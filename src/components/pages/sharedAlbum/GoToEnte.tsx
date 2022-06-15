import { ENTE_WEBSITE_LINK } from 'constants/urls';
import React, { useEffect, useState } from 'react';
import { Button } from 'react-bootstrap';
import { styled } from '@mui/material';
import GetDeviceOS, { OS } from 'utils/common/deviceDetection';
import constants from 'utils/strings/constants';

const Wrapper = styled('div')`
    position: fixed;
    right: 20px;
`;

const NoStyleAnchor = styled('a')`
    color: inherit;
    text-decoration: none !important;
    &:hover {
        color: #fff !important;
    }
`;

export const ButtonWithLink = ({
    href,
    children,
}: React.PropsWithChildren<{ href: string }>) => (
    <Button id="go-to-ente">
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
            return constants.SIGN_UP;
        }
    };

    return (
        <Wrapper>
            <ButtonWithLink href={ENTE_WEBSITE_LINK}>
                {getButtonText(os)}
            </ButtonWithLink>
        </Wrapper>
    );
}

export default GoToEnte;
