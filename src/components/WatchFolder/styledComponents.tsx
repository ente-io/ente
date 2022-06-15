import { Box, Button } from '@mui/material';
import { styled } from '@mui/material/styles';

export const ModalHeading = styled('h3')({
    fontSize: '28px',
    marginBottom: '24px',
    fontWeight: 600,
});
export const FullWidthButtonWithTopMargin = styled(Button)({
    marginTop: '16px',
    width: '100%',
    borderRadius: '4px',
});
export const PaddedContainer = styled(Box)({
    padding: '24px',
});
export const FixedHeightContainer = styled(Box)({
    height: '450px',
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'space-between',
});
export const FullHeightVerticallyCentered = styled(Box)({
    display: 'flex',
    flexDirection: 'column',
    height: '100%',
    overflowY: 'auto',
    margin: 0,
    padding: 0,
    listStyle: 'none',
    '&::-webkit-scrollbar': {
        width: '6px',
    },
    '&::-webkit-scrollbar-thumb': {
        backgroundColor: 'slategrey',
    },
});
export const NoFoldersTitleText = styled('h4')({
    fontSize: '24px',
    marginBottom: '16px',
    fontWeight: 600,
});
export const BottomMarginSpacer = styled(Box)({
    marginBottom: '10px',
});
export const HorizontalFlex = styled(Box)({
    display: 'flex',
    flexDirection: 'row',
    justifyContent: 'space-between',
});
export const VerticalFlex = styled(Box)({
    display: 'flex',
    flexDirection: 'column',
});
export const MappingEntryTitle = styled(Box)({
    fontSize: '16px',
    fontWeight: 500,
    marginLeft: '12px',
    marginRight: '6px',
});
export const MappingEntryFolder = styled(Box)({
    fontSize: '14px',
    fontWeight: 500,
    marginTop: '2px',
    marginLeft: '12px',
    marginRight: '6px',
    marginBottom: '6px',
    lineHeight: '18px',
});
export const DialogBoxHeading = styled('h4')({
    fontSize: '24px',
    marginBottom: '16px',
    fontWeight: 600,
});
export const DialogBoxText = styled('p')({
    fontWeight: 500,
});
export const DialogBoxButton = styled(Button)({
    width: '140px',
});
