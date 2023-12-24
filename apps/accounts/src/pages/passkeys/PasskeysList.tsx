import { MenuItemGroup } from '@ente/shared/components/Menu/MenuItemGroup';
import { useEffect, useState } from 'react';
import { getPasskeys } from 'services/passkeysService';
import { Passkey } from 'types/passkey';
import PasskeyListItem from './PasskeyListItem';

const PasskeyComponent = () => {
    const [passkeys, setPasskeys] = useState<Passkey[]>([]);

    const init = async () => {
        const data = await getPasskeys();
        setPasskeys(data.passkeys);
    };

    useEffect(() => {
        init();
    }, []);

    return (
        <>
            <MenuItemGroup>
                {passkeys.map((passkey) => (
                    <PasskeyListItem key={passkey.id} passkey={passkey} />
                ))}
            </MenuItemGroup>
        </>
    );
};

export default PasskeyComponent;
