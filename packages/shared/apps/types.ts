import { NextRouter } from 'next/router';

export interface PageProps {
    appContext: {
        showNavBar: (show: boolean) => void;
    };
    router: NextRouter;
}
