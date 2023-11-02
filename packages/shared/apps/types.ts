import { NextRouter } from 'next/router';
import { APPS } from './constants';

export interface PageProps {
    appContext: {
        showNavBar: (show: boolean) => void;
    };
    router: NextRouter;
    appName: APPS;
}
