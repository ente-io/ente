import { LS_KEYS, getData } from '.';

export const getToken = () => getData(LS_KEYS.USER)?.token;
