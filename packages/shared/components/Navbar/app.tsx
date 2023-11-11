import { EnteLogo } from '../EnteLogo';
import { CenteredFlex } from '../../components/Container';
import NavbarBase from './base';

export default function AppNavbar({ isMobile }) {
    return (
        <NavbarBase isMobile={isMobile}>
            <CenteredFlex>
                <EnteLogo />
            </CenteredFlex>
        </NavbarBase>
    );
}
