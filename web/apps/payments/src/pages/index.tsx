import { Container } from "components/Container";
import { Spinner } from "components/Spinner";
import * as React from "react";
import { parseAndHandleRequest } from "services/billing-service";
import constants from "utils/strings";

export default function Home() {
    const [failed, setFailed] = React.useState(false);

    React.useEffect(() => {
        async function main() {
            try {
                await parseAndHandleRequest();
            } catch {
                setFailed(true);
            }
        }
        // TODO: audit
        // eslint-disable-next-line @typescript-eslint/no-floating-promises
        main();
    }, []);

    return (
        <Container>
            {failed ? constants.SOMETHING_WENT_WRONG : <Spinner />}
        </Container>
    );
}
