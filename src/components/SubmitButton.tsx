import React from 'react';
import { Button, Spinner } from 'react-bootstrap';

interface Props {
    loading: boolean;
    buttonText: string;
    inline?: any;
}
const SubmitButton = ({ loading, buttonText, inline }: Props) => (
    <Button
        className="submitButton"
        variant="outline-success"
        type="submit"
        block={!inline}
        disabled={loading}
        style={{ padding: '6px 1em' }}
    >
        {loading ? (
            <Spinner
                as="span"
                animation="border"
                style={{ width: '22px', height: '22px', borderWidth: '0.20em' }}
            />
        ) : (
            buttonText
        )}
    </Button>
);

export default SubmitButton;
