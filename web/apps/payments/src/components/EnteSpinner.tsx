import * as React from "react";
import { Spinner } from "react-bootstrap";

export const EnteSpinner: React.FC = () => {
    return (
        <Spinner animation="border" variant="success" role="status">
            <span className="sr-only">Loading...</span>
        </Spinner>
    );
};
