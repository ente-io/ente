import { getPaymentsURL } from '@ente/shared/network/api';

export const getDesktopRedirectURL = () =>
    `${getPaymentsURL()}/desktop-redirect`;
