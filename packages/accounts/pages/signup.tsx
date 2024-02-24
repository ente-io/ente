import SignUp from "@ente/accounts/components/SignUp";
import { PAGES } from "@ente/accounts/constants/pages";
import { LS_KEYS, getData } from "@ente/shared//storage/localStorage";
import { PageProps } from "@ente/shared/apps/types";
import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import { useEffect, useState } from "react";

export default function SignUpPage({ router, appContext, appName }: PageProps) {
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (user?.email) {
            router.push(PAGES.VERIFY);
        }
        setLoading(false);
        appContext.showNavBar(true);
    }, []);

    const login = () => {
        router.push(PAGES.LOGIN);
    };

    return (
        <VerticallyCentered>
            {loading ? (
                <EnteSpinner />
            ) : (
                <FormPaper>
                    <SignUp login={login} router={router} appName={appName} />
                </FormPaper>
            )}
        </VerticallyCentered>
    );
}
