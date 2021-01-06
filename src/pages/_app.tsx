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
import 'react-photoswipe/lib/photoswipe.css';
import localForage from 'localforage';
import UploadButton from 'pages/gallery/components/UploadButton';
import FileUpload from './gallery/components/DragAndDropUpload';

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
        background-color: #303030;
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
`;

const Image = styled.img`
  max-height: 28px;
  margin-right: 5px;
`;

const FlexContainer = styled.div`
  flex: 1;
`;

export default function App({ Component, pageProps }) {
  const router = useRouter();
  const [user, setUser] = useState();
  const [loading, setLoading] = useState(false);
  const [modalView, setModalView] = useState(false);

  const closeModal = () => setModalView(false);
  const showModal = () => setModalView(true);

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
    localForage.clear();
    const cache = await caches.delete('thumbs');
    router.push('/');
  };

  return (
    <>
      <FileUpload
        noClick
        closeModal={closeModal}
        showModal={showModal}
      >
        <Head>
          <title>ente.io | Privacy friendly alternative to Google Photos</title>
        </Head>
        <GlobalStyles />
        <Navbar>
          <FlexContainer>
            <Image alt='logo' src='/icon.png' />
            {constants.COMPANY_NAME}
          </FlexContainer>
          {user && (
            <>
              <UploadButton showModal={showModal} />
              <Button variant='link' onClick={logout}>
                <PowerSettings />
              </Button>
            </>
          )}
        </Navbar>
        {loading ? (
          <Container>
            <Spinner animation='border' role='status' variant='primary'>
              <span className='sr-only'>Loading...</span>
            </Spinner>
          </Container>
        ) : (
            <Component modalView={modalView} closeModal={closeModal}
              showModal={showModal} />
          )}
      </FileUpload>
    </>
  );
}
