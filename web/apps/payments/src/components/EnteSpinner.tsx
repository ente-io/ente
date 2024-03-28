import { Spinner } from "react-bootstrap";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export default function EnteSpinner(props: any) {
    return (
        <Spinner {...props} animation="border" variant="success" role="status">
            <span className="sr-only">Loading...</span>
        </Spinner>
    );
}
