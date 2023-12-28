import { MenuItemGroup } from '@ente/shared/components/Menu/MenuItemGroup';
import { Passkey } from 'types/passkey';
import PasskeyListItem from './PasskeyListItem';
import MenuItemDivider from '@ente/shared/components/Menu/MenuItemDivider';
import { Fragment } from 'react';

interface IProps {
    passkeys: Passkey[];
}

const PasskeyComponent = (props: IProps) => {
    return (
        <>
            <MenuItemGroup>
                {props.passkeys?.map((passkey, i) => (
                    <Fragment key={passkey.id}>
                        <PasskeyListItem passkey={passkey} />
                        {i < props.passkeys.length - 1 && <MenuItemDivider />}
                    </Fragment>
                ))}
            </MenuItemGroup>
        </>
    );
};

export default PasskeyComponent;
