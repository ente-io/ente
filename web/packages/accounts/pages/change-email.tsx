import { VerticallyCentered } from "@ente/shared/components/Container";
import { t } from "i18next";
import { useEffect } from "react";

import ChangeEmailForm from "@ente/accounts/components/ChangeEmail";
import { PAGES } from "@ente/accounts/constants/pages";
import { PageProps } from "@ente/shared/apps/types";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import FormPaperTitle from "@ente/shared/components/Form/FormPaper/Title";
import { getData, LS_KEYS } from "@ente/shared/storage/localStorage";

function ChangeEmailPage({ router, appName, appContext }: PageProps) {
    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (!user?.token) {
            router.push(PAGES.ROOT);
        }
    }, []);

    return (
        <VerticallyCentered>
            <FormPaper>
                <FormPaperTitle>{t("CHANGE_EMAIL")}</FormPaperTitle>
                <ChangeEmailForm
                    router={router}
                    appName={appName}
                    appContext={appContext}
                />
            </FormPaper>
        </VerticallyCentered>
    );
}

export default ChangeEmailPage;
