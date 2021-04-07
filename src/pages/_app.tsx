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
        color: #aaa;
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
    .btn-success , btn:focus {
        background: #2dc262;
        border-color: #29a354;
    }
    .btn-success:hover {
        background-color: #29a354;
        border-color: #2dc262;
    }
    .btn-success:disabled {
        background-color: #69b383;
    }
    .btn-outline-success {
        color: #2dc262;
        border-color: #2dc262;
        border-width: 2px;
    }
    .btn-outline-success:hover {
        background: #2dc262;
    }
    .btn-outline-danger {
        border-width: 2px;
    }
    .btn-outline-secondary {
        border-width: 2px;
    }
    .btn-outline-primary {
        border-width: 2px;
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
        background-color: #a9f7ff;
        color: #000000;
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
        width: 28px;
        height: 20px;
        top:25px;
        left: 32px;
    }
    .bm-burger-bars {
        background: #bdbdbd;
    }
    .bm-menu-wrap {
        top:0px;
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

const FlexContainer = styled.div`
    flex: 1;
    text-align: center;
`;

export interface BannerMessage {
    message: string;
    variant: string;
}

sentryInit();
export default function App({ Component, pageProps, err }) {
    const router = useRouter();
    const [loading, setLoading] = useState(false);
    const [collectionSelectorView, setCollectionSelectorView] = useState(false);

    function closeCollectionSelector() {
        setCollectionSelectorView(false);
    }
    function showCollectionSelector() {
        setCollectionSelectorView(true);
    }

    useEffect(() => {
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
            setLoading(false);
        });
    }, []);
    const onDropAccepted = useCallback(() => {
        if (acceptedFiles != null && !collectionSelectorView) {
            showCollectionSelector();
        }
    }, []);
    const { getRootProps, getInputProps, open, acceptedFiles } = useDropzone({
        noClick: true,
        noKeyboard: true,
        accept: 'image/*, video/*, application/json, ',
        onDropAccepted,
    });
    return (
        <>
            <Head>
                <title>{constants.TITLE}</title>
                <script async src={`https://sa.ente.io/latest.js`} />
            </Head>
            <GlobalStyles />
            <Navbar>
                <FlexContainer>
                    <Image
                        style={{ height: '24px' }}
                        alt="logo"
                        src="/icon.svg"
                    />
                </FlexContainer>
            </Navbar>
            {loading ? (
                <Container>
                    <Spinner animation="border" role="status" variant="success">
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
                    err={err}
                />
            )}
        </>
    );
}
