import { EnteMenuItem } from '@ente/shared/components/Menu/EnteMenuItem';
import { Passkey } from 'types/passkey';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import { useContext } from 'react';
import { PasskeysContext } from '.';
import KeyIcon from '@mui/icons-material/Key';

interface IProps {
    passkey: Passkey;
}

const PasskeyListItem = (props: IProps) => {
    const { setSelectedPasskey, setShowPasskeyDrawer } =
        useContext(PasskeysContext);

    return (
        <EnteMenuItem
            onClick={() => {
                setSelectedPasskey(props.passkey);
                setShowPasskeyDrawer(true);
            }}
            startIcon={<KeyIcon />}
            endIcon={<ChevronRightIcon />}
            label={props.passkey?.friendlyName}
        />
    );
};

export default PasskeyListItem;
