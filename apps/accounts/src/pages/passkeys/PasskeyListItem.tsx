import { EnteMenuItem } from '@ente/shared/components/Menu/EnteMenuItem';
import { Passkey } from 'types/passkey';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import { useContext } from 'react';
import { PasskeysContext } from '.';

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
            key={props.passkey.id}
            endIcon={<ChevronRightIcon />}
            label={props.passkey.friendlyName}
        />
    );
};

export default PasskeyListItem;
