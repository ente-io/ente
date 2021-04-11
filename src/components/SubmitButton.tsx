import React from 'react';
import { Button, Spinner } from 'react-bootstrap';

interface Props {
    loading: boolean;
    buttonText: string;
}
const SubmitButton = ({ loading, buttonText }: Props) => (
    <Button
        variant="success"
        type="submit"
        block
        disabled={loading}
        style={{ padding: '0', height: '40px' }}
    >
        {loading ? (
            <Spinner
                as="span"
                style={{
                    height: '35px',
                    width: '35px',
                }}
                animation="border"
            />
        ) : (
            buttonText
        )}
    </Button>
);

export default SubmitButton;
