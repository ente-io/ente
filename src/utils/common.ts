import { app } from 'electron';
export const isDev = !app.isPackaged;
