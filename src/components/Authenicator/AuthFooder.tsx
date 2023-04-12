import { Button } from '@mui/material';

export const AuthFooter = () => {
    return (
        <div
            style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
            }}>
            <p>Download our mobile app to add &amp; manage your secrets.</p>
            <a href="https://github.com/ente-io/auth#-download" download>
                <Button
                    style={{
                        backgroundColor: 'green',
                        padding: '12px 18px',
                        color: 'white',
                    }}>
                    Download
                </Button>
            </a>
        </div>
    );
};
