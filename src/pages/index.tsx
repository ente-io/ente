import React, { useContext, useEffect, useState } from 'react';
import Carousel from 'react-bootstrap/Carousel';
import Button from 'react-bootstrap/Button';
import styled from 'styled-components';
import { AppContext } from './_app';
import Login from 'components/Login';
import { useRouter } from 'next/router';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import EnteSpinner from 'components/EnteSpinner';
import SignUp from 'components/SignUp';
import constants from 'utils/strings/constants';

const Container = styled.div`
    display: flex;
    flex: 1;
    align-items: center;
    justify-content: center;

    @media(max-width: 1024px) {
        flex-direction: column;
    }
`;

const SlideContainer = styled.div`
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;

    @media(max-width: 1024px) {
        flex-grow: 0;
    }
`;

const DesktopBox = styled.div`
    flex: 1;
    height: 100%;
    padding: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: #242424;

    @media(max-width: 1024px) {
        display: none;
    }
`;

const MobileBox = styled.div`
    display: none;

    @media(max-width: 1024px) {
        display: flex;
        flex-direction: column;
        padding-bottom: 20px
    }
`;

const SideBox = styled.div`
    display: flex;
    flex-direction: column;
`;

const Strong = styled.strong`
    color: #fff;
`;

const TextContainer = styled.div`
    padding: 20px;
    max-width: 300px;
    margin: 0 auto;
`;

const UpperText = styled(TextContainer)`
    font-size: 24px;
    max-width: 100%;
    margin-bottom: 20px;
`;

const FeatureText = styled.div`
    color: #2dc262;
    font-weight: bold;
    padding-top: 20px;
    font-size: 24px;
`;

const Img = styled.img`
    height: 250px;
    object-fit: contain;
`;

export default function LandingPage() {
    const router = useRouter();
    const appContext = useContext(AppContext);
    const [loading, setLoading] = useState(true);
    const [showLogin, setShowLogin] = useState(true);

    useEffect(() => {
        const main = async () =>{
            const user = getData(LS_KEYS.USER);
            if (user?.email) {
                await router.push('/verify');
            }
            setLoading(false);
        };
        main();
        appContext.showNavBar(false);
    }, []);

    const signUp = () => setShowLogin(false);
    const login = () => setShowLogin(true);

    return <Container>
        {loading ? <EnteSpinner /> :
            (<>
                <SlideContainer>
                    <UpperText>
                        with <Strong>ente</Strong> your <Strong>memories</Strong> are
                    </UpperText>
                    <Carousel controls={false}>
                        <Carousel.Item>
                            <Img src="/images/slide-1.png" />
                            <FeatureText>protected</FeatureText>
                            <TextContainer>end-to-end encrypted with your password, visible only to you</TextContainer>
                        </Carousel.Item>
                        <Carousel.Item>
                            <Img src="/images/slide-2.png" />
                            <FeatureText>synced</FeatureText>
                            <TextContainer>available across all your devices, web, android and ios</TextContainer>
                        </Carousel.Item>
                        <Carousel.Item>
                            <Img src="/images/slide-3.png" />
                            <FeatureText>preserved</FeatureText>
                            <TextContainer>reliably replicated to a fallout shelter, designed to outlive</TextContainer>
                        </Carousel.Item>
                    </Carousel>
                </SlideContainer>
                <MobileBox>
                    <Button
                        variant="outline-success"
                        size="lg"
                        style={{ color: '#fff', padding: '10px 50px' }}
                        onClick={() => router.push('signup')}
                    >
                        {constants.SIGN_UP}
                    </Button>
                    <br/>
                    <Button
                        variant="link"
                        size="lg"
                        style={{ color: '#fff', padding: '10px 50px' }}
                        onClick={() => router.push('login')}
                    >
                        {constants.SIGN_IN}
                    </Button>
                </MobileBox>
                <DesktopBox>
                    <SideBox>
                        { showLogin ? <Login signUp={signUp} /> : <SignUp login={login} />}
                    </SideBox>
                </DesktopBox>
            </>)}
    </Container>;
}
