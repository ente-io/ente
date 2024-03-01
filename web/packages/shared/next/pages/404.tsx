import { VerticallyCentered } from "@ente/shared/components/Container";
import { t } from "i18next";
import { useEffect, useState } from "react";

import { PageProps } from "@ente/shared/apps/types";
import EnteSpinner from "@ente/shared/components/EnteSpinner";

export default function NotFound({ appContext }: PageProps) {
    const [loading, setLoading] = useState(true);
    useEffect(() => {
        appContext.showNavBar(true);
        setLoading(false);
    }, []);
    return (
        <VerticallyCentered>
            {loading ? <EnteSpinner /> : t("NOT_FOUND")}
        </VerticallyCentered>
    );
}
