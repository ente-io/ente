import React, { useContext, useEffect } from 'react';
import { AppContext } from './_app';

export default function LandingPage() {
    const appContext = useContext(AppContext);

    useEffect(() => {
        appContext.showNavBar(false);
    }, []);

    return <div />;
}
