import { MenuItemGroup } from '@ente/shared/components/Menu/MenuItemGroup';
import { Passkey } from 'types/passkey';
import PasskeyListItem from './PasskeyListItem';
import MenuItemDivider from '@ente/shared/components/Menu/MenuItemDivider';

interface IProps {
    passkeys: Passkey[];
}

const PasskeyComponent = (props: IProps) => {
    return (
        <>
            <MenuItemGroup>
                {props.passkeys.map((passkey, i) => (
                    <>
                        <PasskeyListItem key={passkey.id} passkey={passkey} />
                        {i < props.passkeys.length - 1 && <MenuItemDivider />}
                    </>
                ))}
            </MenuItemGroup>
        </>
    );
};

export default PasskeyComponent;
