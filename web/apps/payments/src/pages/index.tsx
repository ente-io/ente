import { Container } from "components/Container";
import { EnteSpinner } from "components/EnteSpinner";
import * as React from "react";
import { parseAndHandleRequest } from "services/billingService";
import { CUSTOM_ERROR } from "utils/error";
import constants from "utils/strings";

export default function Home() {
    const [errorMessageView, setErrorMessageView] = React.useState(false);
    const [loading, setLoading] = React.useState(false);

    React.useEffect(() => {
        async function main() {
            try {
                setLoading(true);
                await parseAndHandleRequest();
            } catch (e: unknown) {
                if (
                    e instanceof Error &&
                    e.message === CUSTOM_ERROR.DIRECT_OPEN_WITH_NO_QUERY_PARAMS
                ) {
                    window.location.href = "https://ente.io";
                } else {
                    setErrorMessageView(true);
                }
            }
        }
        // TODO: audit
        // eslint-disable-next-line @typescript-eslint/no-floating-promises
        main();
    }, []);

    return (
        <Container>
            {errorMessageView ? (
                <div>{constants.SOMETHING_WENT_WRONG}</div>
            ) : (
                loading && <EnteSpinner />
            )}
        </Container>
    );
}
