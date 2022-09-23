import { getPaymentsURL } from 'utils/common/apiUtil';

export const getDesktopRedirectURL = () =>
    `${getPaymentsURL()}/desktop-redirect`;
