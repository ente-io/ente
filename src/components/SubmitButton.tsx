import React from 'react';
import { Button, Spinner } from 'react-bootstrap';

interface Props {
    loading: boolean;
    buttonText: string;
}
const SubmitButton = ({ loading, buttonText }: Props) => (
    <Button variant="success" type="submit" block disabled={loading}>
        {loading ? (
            <Spinner
                as="span"
                style={{
                    height: '20px',
                    width: '20px',
                }}
                animation="border"
            />
        ) : (
            buttonText
        )}
    </Button>
);

export default SubmitButton;
