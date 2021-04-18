import React from 'react';
import { Button } from 'react-bootstrap';
import EnteSpinner from './EnteSpinner';

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
            <EnteSpinner
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
