import { PageProps } from "@ente/shared/apps/types";
import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import { useEffect, useState } from "react";
import Login from "../components/Login";
import { PAGES } from "../constants/pages";

export default function LoginPage({ appContext, router, appName }: PageProps) {
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (user?.email) {
            router.push(PAGES.VERIFY);
        }
        setLoading(false);
        appContext.showNavBar(true);
    }, []);

    const register = () => {
        router.push(PAGES.SIGNUP);
    };

    return loading ? (
        <VerticallyCentered>
            <EnteSpinner />
        </VerticallyCentered>
    ) : (
        <VerticallyCentered>
            <FormPaper>
                <Login signUp={register} appName={appName} />
            </FormPaper>
        </VerticallyCentered>
    );
}
