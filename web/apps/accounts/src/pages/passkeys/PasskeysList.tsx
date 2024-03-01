import MenuItemDivider from "@ente/shared/components/Menu/MenuItemDivider";
import { MenuItemGroup } from "@ente/shared/components/Menu/MenuItemGroup";
import { Fragment } from "react";
import { Passkey } from "types/passkey";
import PasskeyListItem from "./PasskeyListItem";

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
