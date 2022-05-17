// styled.d.ts
import 'styled-components';
import { Theme } from '@mui/material';

declare module 'styled-components' {
    export interface DefaultTheme extends Theme {}
}
