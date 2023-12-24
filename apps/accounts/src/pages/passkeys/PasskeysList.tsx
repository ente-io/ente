import { MenuItemGroup } from '@ente/shared/components/Menu/MenuItemGroup';
import { Passkey } from 'types/passkey';
import PasskeyListItem from './PasskeyListItem';

interface IProps {
    passkeys: Passkey[];
}

const PasskeyComponent = (props: IProps) => {
    return (
        <>
            <MenuItemGroup>
                {props.passkeys.map((passkey) => (
                    <PasskeyListItem key={passkey.id} passkey={passkey} />
                ))}
            </MenuItemGroup>
        </>
    );
};

export default PasskeyComponent;
