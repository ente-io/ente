import React from 'react';
import { Button, Spinner } from 'react-bootstrap';

interface Props {
    loading: boolean;
    buttonText: string;
}
const SubmitButton = ({ loading, buttonText }: Props) => (
    <Button
        variant="outline-success"
        type="submit"
        block
        disabled={loading}
        style={{ padding: '0', height: '40px' }}
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
