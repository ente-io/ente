import { Button } from '@mui/material';
import { t } from 'i18next';

export const AuthFooter = () => {
    return (
        <div
            style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
            }}>
            <p>{t('DOWNLOAD_AUTH_MOBILE_APP')}</p>
            <a href="https://github.com/ente-io/auth#-download" download>
                <Button
                    style={{
                        backgroundColor: 'green',
                        padding: '12px 18px',
                        color: 'white',
                    }}>
                    {t('DOWNLOAD')}
                </Button>
            </a>
        </div>
    );
};
