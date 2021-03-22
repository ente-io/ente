import React, { useCallback, useEffect, useState } from 'react';
import styled, { createGlobalStyle } from 'styled-components';
import Navbar from 'components/Navbar';
import constants from 'utils/strings/constants';
import Spinner from 'react-bootstrap/Spinner';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import Container from 'components/Container';
import Head from 'next/head';
import 'bootstrap/dist/css/bootstrap.min.css';
import 'photoswipe/dist/photoswipe.css';

import UploadButton from 'pages/gallery/components/UploadButton';
import { sentryInit } from '../utils/sentry';
import { useDropzone } from 'react-dropzone';
import Sidebar from 'components/Sidebar';

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
    .modal {
        z-index: 2000;
    }
    .modal .modal-header, .modal .modal-footer {
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
    }
    .btn-primary:hover {
        background-color: #29a354;
        border-color: #2dc262;
    }
    .btn-primary:disabled {
        background-color: #69b383;
    }
    .btn-outline-success {
        color: #2dc262;
        border-color: #2dc262;
    }
    .btn-outline-success:hover {
        background: #2dc262;
    }
    .card {
        background-color: #242424;
        color: #fff;
        border-radius: 12px;
    }
    .jumbotron{
        background-color: #191919;
        color: #fff;
        text-align: center;
        margin-top: 50px;
    }
    .alert-success {
        background-color: #c4ffd6;
    }
    .alert-primary {
        background-color: #c4ffd6;
    }
    .ente-modal{
        width: 500px;
        max-width:100%;
    } 
    .bm-burger-button {
        position: fixed;
        width: 26px;
        height: 22px;
        left: 16px;
        top: 22px;
    }
    .bm-burger-bars {
        background: #bdbdbd;
    }
    .bm-menu {
        background: #131313;
        padding: 2.5em 1.5em 0;
        font-size: 1.15em;
        color:#fff
    }
    .bm-cross {
        background: #fff;
    }
    .bg-upload-progress-bar {
        background-color: #2dc262;
    }
`;

const Image = styled.img`
    max-height: 28px;
    margin-right: 5px;
`;

const FlexContainer = styled.div<{sideMargin: boolean}>`
    flex: 1;
    text-align: center;
    ${props => props.sideMargin && 'margin-left: 48px;'}
`;

sentryInit();
export default function App({ Component, pageProps, err }) {
    const router = useRouter();
    const [user, setUser] = useState();
    const [loading, setLoading] = useState(false);
    const [navbarIconView, setNavbarIconView] = useState(false);
    const [collectionSelectorView, setCollectionSelectorView] = useState(false);

    function closeCollectionSelector() {
        setCollectionSelectorView(false);
    }
    function showCollectionSelector() {
        setCollectionSelectorView(true);
    }

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

    const { getRootProps, getInputProps, open, acceptedFiles } = useDropzone({
        noClick: true,
        noKeyboard: true,
        accept: 'image/*, video/*, application/json, ',
    });
    return (
        <>
            <Head>
                <title>{constants.TITLE}</title>
                <script async src={`https://sa.ente.io/latest.js`} />
            </Head>
            <GlobalStyles />
            <div style={{ display: navbarIconView ? 'block' : 'none' }}>
                <Sidebar setNavbarIconView={setNavbarIconView} />
            </div>
            <Navbar>
                <FlexContainer sideMargin={navbarIconView}>
                    <Image
                        style={{ height: '24px' }}
                        alt="logo"
                        src="/icon.svg"
                    />
                </FlexContainer>
                {navbarIconView && <UploadButton openFileUploader={open} />}
            </Navbar>
            {loading ? (
                <Container>
                    <Spinner animation="border" role="status" variant="primary">
                        <span className="sr-only">Loading...</span>
                    </Spinner>
                </Container>
            ) : (
                <Component
                    getRootProps={getRootProps}
                    getInputProps={getInputProps}
                    openFileUploader={open}
                    acceptedFiles={acceptedFiles}
                    collectionSelectorView={collectionSelectorView}
                    showCollectionSelector={showCollectionSelector}
                    closeCollectionSelector={closeCollectionSelector}
                    setNavbarIconView={setNavbarIconView}
                    err={err}
                />
            )}
        </>
    );
}
