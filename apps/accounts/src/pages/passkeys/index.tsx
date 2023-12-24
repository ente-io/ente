import { CenteredFlex } from '@ente/shared/components/Container';
import SingleInputForm from '@ente/shared/components/SingleInputForm';
import { Box } from '@mui/material';

const Passkeys = () => {
    const handleSubmit = async (inputValue: string) => {
        console.log('inputValue', inputValue);
    };

    return (
        <>
            <CenteredFlex>
                <Box>
                    <SingleInputForm
                        fieldType="text"
                        placeholder="Passkey Name"
                        buttonText="Add Passkey"
                        initialValue={''}
                        blockButton
                        callback={handleSubmit}
                    />
                </Box>
            </CenteredFlex>
        </>
    );
};

export default Passkeys;
