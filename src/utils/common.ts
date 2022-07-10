import { app } from 'electron';
export const isDev = !app.isPackaged;

export const getAppVersion = () => app.getVersion();
