import React, { createContext, useEffect, useState } from 'react';
import styled, { createGlobalStyle } from 'styled-components';
import Navbar from 'components/Navbar';
import constants from 'utils/strings/constants';
import { useRouter } from 'next/router';
import Container from 'components/Container';
import Head from 'next/head';
import 'bootstrap/dist/css/bootstrap.min.css';
import 'photoswipe/dist/photoswipe.css';
import EnteSpinner from 'components/EnteSpinner';
import { logError } from '../utils/sentry';
import { Workbox } from 'workbox-window';
import { getEndpoint } from 'utils/common/apiUtil';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import HTTPService from 'services/HTTPService';

const GlobalStyles = createGlobalStyle`
/* ubuntu-regular - latin */
@font-face {
  font-family: 'Ubuntu';
  font-style: normal;
  font-weight: 400;
  src: local(''),
       url('/fonts/ubuntu-v15-latin-regular.woff2') format('woff2'), /* Chrome 26+, Opera 23+, Firefox 39+ */
       url('/fonts/ubuntu-v15-latin-regular.woff') format('woff'); /* Chrome 6+, Firefox 3.6+, IE 9+, Safari 5.1+ */
}

/* ubuntu-700 - latin */
@font-face {
  font-family: 'Ubuntu';
  font-style: normal;
  font-weight: 700;
  src: local(''),
       url('/fonts/ubuntu-v15-latin-700.woff2') format('woff2'), /* Chrome 26+, Opera 23+, Firefox 39+ */
       url('/fonts/ubuntu-v15-latin-700.woff') format('woff'); /* Chrome 6+, Firefox 3.6+, IE 9+, Safari 5.1+ */
}
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
        font-family:Ubuntu, Arial, sans-serif !important;
    }
    :is(h1, h2, h3, h4, h5, h6) {
        color: #d7d7d7;
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

    .modal {
        z-index: 2000;
    }
    .modal-dialog-centered {
        min-height: -webkit-calc(80% - 3.5rem);
        min-height: -moz-calc(80% - 3.5rem);
        min-height: calc(80% - 3.5rem);
    }
    .modal .modal-header, .modal .modal-footer {
        border-color: #444 !important;
    }
    .modal .modal-header .close {
        color: #aaa;
        text-shadow: none;
    }
    .modal-backdrop {
        z-index:2000;
        opacity:0.8 !important;
    }
    .modal .card , .table {
        background-color: #202020;
        border: none;
    }
    .modal .card > div {
        border-radius: 30px;
        overflow: hidden;
        margin: 0 0 5px 0;
    }
    .modal-content {
        border-radius:15px;
        background-color:#202020 !important;
        color:#aaa;
    }
    .modal-dialog{
        margin:5% auto;
        width:90%;
    }
    .modal-xl{
        max-width:960px!important;
    }
    .pswp-custom {
        opacity: 0.75;
        transition: opacity .2s;
        display: inline-block;
        float: right;
        cursor: pointer;
        border: none;
        height: 44px;
        width: 44px;
    }
    .pswp-custom:hover {
        opacity: 1;
    }
    .download-btn{
        background: url('/download_icon.png') no-repeat;
        background-size: 20px 20px;
        background-position: center;
    }
    .info-btn{
        background: url('/info_icon.png') no-repeat;
        background-size: 20px 20px;
        background-position: center;
    }
    .share-btn{
        background: url('/share_icon.png') no-repeat;
        background-size: 20px 20px;
        background-position: center;
    }
    .btn.focus , .btn:focus{
        box-shadow: none;
    }
    .btn-success {
        background: #2dc262;
        border-color: #29a354;
    }
    .btn-success:hover ,.btn-success:focus .btn-success:active{
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
    .btn-outline-danger, .btn-outline-secondary, .btn-outline-primary{
        border-width: 2px;
    }
    .card {
        background-color: #242424;
        color: #d1d1d1;
        border-radius: 12px;
    }
    .jumbotron{
        background-color: #191919;
        color: #d1d1d1;
        text-align: center;
        margin-top: 50px;
    }
    .alert-success {
        background-color: rgb(235, 255, 243);
        color: #000000;
    }
    .alert-primary {
        background-color: #c4ffd6;
    }
    .bm-burger-button {
        position: fixed;
        width: 24px;
        height: 16px;
        top:27px;
        left: 32px;
        z-index:100 !important;
    }
    .bm-burger-bars {
        background: #bdbdbd;
    }
    .bm-menu-wrap {
        top:0px;
      }
    .bm-menu {
        background: #131313;
        font-size: 1.15em;
        color:#d1d1d1;
        display: flex;
    }
    .bm-cross {
        background: #d1d1d1;
    }
    .bm-cross-button {
        top: 20px !important;
    }
    .bm-item-list {
        display: flex !important;
        flex-direction: column;
        max-height: 100%;
        flex: 1;
    }
    .bm-item {
        padding: 20px;
    }
    .bm-overlay {
        top: 0;
        background: rgba(0, 0, 0, 0.8) !important;
    }
    .bg-upload-progress-bar {
        background-color: #2dc262;
    }
    .custom-switch.custom-switch-md .custom-control-label {
        padding-left: 2rem;
        padding-bottom: 1.5rem;
    }
    
    .custom-switch.custom-switch-md .custom-control-label::before {
        height: 1.5rem;
        background-color: #303030;
        border: none;
        width: calc(2.5rem + 0.75rem);
        border-radius: 3rem;
    }
    .custom-switch.custom-switch-md:active .custom-control-label::before {
        background-color: #303030;
    }
    
    .custom-switch.custom-switch-md .custom-control-label::after {
        top:2px;
        background:#c4c4c4;
        width: calc(2.0rem - 4px);
        height: calc(2.0rem - 4px);
        border-radius: calc(2rem - (2.0rem / 2));
        left: -38px;
    }
    
    .custom-switch.custom-switch-md .custom-control-input:checked ~ .custom-control-label::after {
        transform: translateX(calc(2.0rem - 0.25rem));
        background:#c4c4c4;
    }

    .custom-control-input:checked ~ .custom-control-label::before {
        background-color: #29a354;
    }

    .bold-text{
        color: #ECECEC;
        line-height: 24px;
        font-size: 24px;
    }
    .dropdown-item:active{
        color: #16181b;
        text-decoration: none;
        background-color: #e9ecef;
    }
    .submitButton:hover > .spinner-border{
        color:white;
    }
    hr{
        border-top: 1rem solid #444 !important;
    }
    .list-group-item:hover{
        background-color:#343434 !important;
    }
    .list-group-item:active , list-group-item:focus{
        background-color:#000 !important;
    }
    .arrow::after{
        border-bottom-color:#282828 !important;
    }
    .carousel-inner {
        padding-bottom: 50px !important;
    }
    .carousel-indicators li {
        width: 10px;
        height: 10px;
        border-radius: 50%;
        margin-right: 12px;
    }
    .carousel-indicators .active {
        background-color: #2dc262;
    }
    div.otp-input input {
        width: 2em !important;
        height: 3em;
        margin: 0 10px;
    }
`;

export const LogoImage = styled.img`
    max-height: 28px;
    margin-right: 5px;
`;

const FlexContainer = styled.div`
    flex: 1;
    text-align: center;
`;

export const MessageContainer = styled.div`
    background-color: #111;
    padding: 0;
    font-size: 14px;
    text-align: center;
    line-height: 32px;
`;

export interface BannerMessage {
    message: string;
    variant: string;
}


type AppContextType = {
    showNavBar: (show: boolean) => void;
    sharedFiles: File[];
    resetSharedFiles: () => void;
}

export const AppContext = createContext<AppContextType>(null);

const redirectMap = {
    roadmap: (token: string) => `${getEndpoint()}/users/roadmap?token=${encodeURIComponent(token)}`,
};

export default function App({ Component, err }) {
    const router = useRouter();
    const [loading, setLoading] = useState(false);
    const [offline, setOffline] = useState(
        typeof window !== 'undefined' && !window.navigator.onLine,
    );
    const [showNavbar, setShowNavBar] = useState(false);
    const [sharedFiles, setSharedFiles] = useState<File[]>(null);
    const [redirectName, setRedirectName] = useState<string>(null);

    useEffect(() => {
        if (
            !('serviceWorker' in navigator) ||
            process.env.NODE_ENV !== 'production'
        ) {
            console.warn('Progressive Web App support is disabled');
            return;
        }
        const wb = new Workbox('sw.js', { scope: '/' });
        wb.register();

        if ('serviceWorker' in navigator) {
            navigator.serviceWorker.onmessage = (event) => {
                if (event.data.action === 'upload-files') {
                    const files = event.data.files;
                    setSharedFiles(files);
                }
            };
        }

        HTTPService.getInterceptors().response.use(
            (resp) => resp,
            (error) => {
                logError(error);
                return Promise.reject(error);
            },
        );
    }, []);

    const setUserOnline = () => setOffline(false);
    const setUserOffline = () => setOffline(true);
    const resetSharedFiles = () => setSharedFiles(null);

    useEffect(() => {
        console.log(
            `%c${constants.CONSOLE_WARNING_STOP}`,
            'color: red; font-size: 52px;',
        );
        console.log(`%c${constants.CONSOLE_WARNING_DESC}`, 'font-size: 20px;');

        const query = new URLSearchParams(window.location.search);
        const redirect = query.get('redirect');
        if (redirect && redirectMap[redirect]) {
            const user = getData(LS_KEYS.USER);
            if (user?.token) {
                window.location.href = redirectMap[redirect](user.token);
            } else {
                setRedirectName(redirect);
            }
        }

        router.events.on('routeChangeStart', (url: string) => {
            if (window.location.pathname !== url.split('?')[0]) {
                setLoading(true);
            }

            if (redirectName) {
                const user = getData(LS_KEYS.USER);
                if (user?.token) {
                    window.location.href = redirectMap[redirectName](user.token);
                }
            }
        });

        router.events.on('routeChangeComplete', () => {
            setLoading(false);
        });

        window.addEventListener('online', setUserOnline);
        window.addEventListener('offline', setUserOffline);

        return () => {
            window.removeEventListener('online', setUserOnline);
            window.removeEventListener('offline', setUserOffline);
        };
    }, [redirectName]);

    const showNavBar = (show: boolean) => setShowNavBar(show);

    return (
        <>
            <Head>
                <title>{constants.TITLE}</title>
                {/* Cloudflare Web Analytics */}
                {process.env.NODE_ENV === 'production' &&
                    <script
                        defer
                        src="https://static.cloudflareinsights.com/beacon.min.js"
                        data-cf-beacon='{"token": "6a388287b59c439cb2070f78cc89dde1"}'
                    />
                }
                {/* End Cloudflare Web Analytics  */}
            </Head>
            <GlobalStyles />
            {showNavbar && <Navbar>
                <FlexContainer>
                    <LogoImage
                        style={{ height: '24px', padding: '3px' }}
                        alt="logo"
                        src="/icon.svg"
                    />
                </FlexContainer>
            </Navbar>}
            <MessageContainer>{offline && constants.OFFLINE_MSG}</MessageContainer>
            {sharedFiles &&
                (router.pathname === '/gallery' ?
                    <MessageContainer>{constants.FILES_TO_BE_UPLOADED(sharedFiles.length)}</MessageContainer> :
                    <MessageContainer>{constants.LOGIN_TO_UPLOAD_FILES(sharedFiles.length)}</MessageContainer>)}
            <AppContext.Provider value={{
                showNavBar,
                sharedFiles,
                resetSharedFiles,
            }}>
                {loading ? (
                    <Container>
                        <EnteSpinner>
                            <span className="sr-only">Loading...</span>
                        </EnteSpinner>
                    </Container>
                ) : (
                    <Component err={err} setLoading={setLoading} />
                )}
            </AppContext.Provider>
        </>
    );
}
