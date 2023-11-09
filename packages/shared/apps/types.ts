import { NextRouter } from 'next/router';
import { APPS } from './constants';
import { SetDialogBoxAttributesV2 } from '@ente/shared/components/DialogBoxV2/types';
import { EmotionCache } from '@emotion/react';
import { AppProps } from 'next/app';

export interface EnteAppProps extends AppProps {
    emotionCache?: EmotionCache;
}

export interface PageProps {
    appContext: {
        showNavBar: (show: boolean) => void;
        isMobile: boolean;
        setDialogBoxAttributesV2: SetDialogBoxAttributesV2;
    };
    router: NextRouter;
    appName: APPS;
}
