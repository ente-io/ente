import { FluidContainer } from 'components/Container';
import { SelectionBar } from '../../Navbar/SelectionBar';
import { useContext } from 'react';
import { Box, IconButton, Tooltip } from '@mui/material';
import { AppContext } from 'pages/_app';
import CloseIcon from '@mui/icons-material/Close';
import BackButton from '@mui/icons-material/ArrowBackOutlined';
import DeleteIcon from '@mui/icons-material/Delete';
import { getTrashFilesMessage } from 'utils/ui';
import { t } from 'i18next';
import { formatNumber } from 'utils/number/format';

interface IProps {
    deleteFileHelper: () => void;
    close: () => void;
    count: number;
    clearSelection: () => void;
}

export default function DeduplicateOptions({
    deleteFileHelper,
    close,
    count,
    clearSelection,
}: IProps) {
    const { setDialogMessage } = useContext(AppContext);

    const trashHandler = () =>
        setDialogMessage(getTrashFilesMessage(deleteFileHelper));

    return (
        <SelectionBar>
            <FluidContainer>
                {count ? (
                    <IconButton onClick={clearSelection}>
                        <CloseIcon />
                    </IconButton>
                ) : (
                    <IconButton onClick={close}>
                        <BackButton />
                    </IconButton>
                )}
                <Box ml={1.5}>
                    {formatNumber(count)} {t('SELECTED')}
                </Box>
            </FluidContainer>
            <Tooltip title={t('DELETE')}>
                <IconButton onClick={trashHandler}>
                    <DeleteIcon />
                </IconButton>
            </Tooltip>
        </SelectionBar>
    );
}
