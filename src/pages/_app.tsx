import React, { useEffect, useState } from 'react';
import styled, { createGlobalStyle } from 'styled-components';
import Navbar from 'components/Navbar';
import constants from 'utils/strings/constants';
import Button from 'react-bootstrap/Button';
import Spinner from 'react-bootstrap/Spinner';
import { clearKeys } from 'utils/storage/sessionStorage';
import { clearData, getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import Container from 'components/Container';
import PowerSettings from 'components/power_settings';
import Head from 'next/head';
import 'bootstrap/dist/css/bootstrap.min.css';
import 'photoswipe/dist/photoswipe.css';
import localForage from 'localforage';
import UploadButton from 'pages/gallery/components/UploadButton';
import FullScreenDropZone from 'components/FullScreenDropZone';

localForage.config({
    driver: localForage.INDEXEDDB,
    name: 'ente-files',
    version: 1.0,
    storeName: 'files',
});

const GlobalStyles = createGlobalStyle`
    html, body {
        padding: 0;
        margin: 0;
        font-family: Arial, Helvetica, sans-serif;
        height: 100%;
        flex: 1;
        display: flex;
        flex-direction: column;
        background-color: #191919;
    }

    #__next {
        flex: 1;
        display: flex;
        flex-direction: column;
    }

    .material-icons {
        vertical-align: middle;
        margin: 8px;
    }
    
    .pswp__item video {
        width: 100%;
        height: 100%;
    }

    .video-loading {
        width: 100%;
        height: 100%;
        position: relative;
    }

    .video-loading > img {
        object-fit: contain;
        width: 100%;
        height: 100%;
    }

    .video-loading > div {
        position: relative;
        top: -50vh;
        left: 50vw;
    }

    :root {
        --primary: #e26f99,
    };

    svg {
        fill: currentColor;
    }

    .pswp__img {
        object-fit: contain;
    }
    .modal-90w{
        width:90vw;
        max-width:960px!important;
    }
    .modal .modal-header, .modal  .modal-footer {
        border-color: #444 !important;
    }
    .modal .modal-header .close {
        color: #aaa;
        text-shadow: none;
    }
    .modal .card {
        background-color: #202020;
        border: none;
        color: #aaa;
    }
    .modal .card > div {
        border-radius: 30px;
        overflow: hidden;
        margin: 0 0 5px 0;
    }
    .modal-content {
        background-color:#202020 !important;
        color:#aaa;
    }
    .download-btn{
        margin-top:10px;
        width: 25px;
        height: 25px;
        float: right;
        background: url('/download_icon.png') no-repeat;
        cursor: pointer;
        background-size: cover;
        border: none;
    }
    .btn-primary {
        background: #2dc262;
        border-color: #29a354;
        padding: 8px;
        padding-left: 24px;
        padding-right: 24px;
    }
    .btn-primary:hover {
        background-color: #29a354;
        border-color: #2dc262;
    }
    .btn-primary:disabled {
        background-color: #69b383;
    }
    .card {
        background-color: #242424;
        color: #fff;
        border-radius: 12px;
    }
`;

const Image = styled.img`
    max-height: 28px;
    margin-right: 5px;
`;

const FlexContainer = styled.div`
    flex: 1;
    text-align: center;
    margin: 16px;
`;

export default function App({ Component, pageProps }) {
    const router = useRouter();
    const [user, setUser] = useState();
    const [loading, setLoading] = useState(false);
    const [uploadButtonView, setUploadButtonView] = useState(false);
    const [uploadModalView, setUploadModalView] = useState(false);

    const closeUploadModal = () => setUploadModalView(false);
    const showUploadModal = () => setUploadModalView(true);

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        setUser(user);
        console.log(
            `%c${constants.CONSOLE_WARNING_STOP}`,
            'color: red; font-size: 52px;'
        );
        console.log(`%c${constants.CONSOLE_WARNING_DESC}`, 'font-size: 20px;');

        router.events.on('routeChangeStart', (url: string) => {
            if (window.location.pathname !== url.split('?')[0]) {
                setLoading(true);
            }
        });

        router.events.on('routeChangeComplete', () => {
            const user = getData(LS_KEYS.USER);
            setUser(user);
            setLoading(false);
        });
    }, []);

    const logout = async () => {
        clearKeys();
        clearData();
        setUploadButtonView(false);
        localForage.clear();
        const cache = await caches.delete('thumbs');
        router.push('/');
    };

    return (
        <FullScreenDropZone showModal={showUploadModal}>
            <Head>
                <title>ente.io | Encrypted Photo Storage</title>
            </Head>
            <GlobalStyles />
            <Navbar>
                {user && (
                    <Button variant="link" onClick={logout}>
                        <PowerSettings />
                    </Button>
                )}
                <FlexContainer>
                    <Image alt="logo" src="/icon.svg" />
                </FlexContainer>
                {uploadButtonView && (
                    <UploadButton showModal={showUploadModal} />
                )}
            </Navbar>
            {loading ? (
                <Container>
                    <Spinner animation="border" role="status" variant="primary">
                        <span className="sr-only">Loading...</span>
                    </Spinner>
                </Container>
            ) : (
                <Component
                    uploadModalView={uploadModalView}
                    showUploadModal={showUploadModal}
                    closeUploadModal={closeUploadModal}
                    setUploadButtonView={setUploadButtonView}
                />
            )}
        </FullScreenDropZone>
    );
}
