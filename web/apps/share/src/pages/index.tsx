import React, { useEffect } from "react";

/**
 * Index page that redirects to ente.io/locker
 *
 * Users visiting the root domain (/) are redirected to the Locker homepage.
 * All share links use the format /token#key and are handled by 404.tsx.
 */
const Page: React.FC = () => {
    useEffect(() => {
        // Redirect to ente.io/locker
        window.location.href = "https://ente.io/locker";
    }, []);

    return null;
};

export default Page;
