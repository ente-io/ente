import { IconButton } from 'components/Container';
import { SelectionBar, SelectionContainer } from '.';
import constants from 'utils/strings/constants';
import DeleteIcon from 'components/icons/DeleteIcon';
import React, { useContext } from 'react';
import styled from 'styled-components';
import { DeduplicateContext } from 'pages/deduplicate';
import LeftArrow from 'components/icons/LeftArrow';
import { SetDialogMessage } from 'components/MessageDialog';
import { IconWithMessage } from 'components/IconWithMessage';
import CloseIcon from 'components/icons/CloseIcon';

const VerticalLine = styled.div`
    position: absolute;
    width: 1px;
    top: 0;
    bottom: 0;
    background: #303030;
`;

const CheckboxText = styled.div`
    margin-left: 0.5em;
    font-size: 16px;
    margin-right: 0.8em;
`;

interface IProps {
    deleteFileHelper: () => void;
    setDialogMessage: SetDialogMessage;
    close: () => void;
    count: number;
    clearSelection: () => void;
}

export default function DeduplicateOptions({
    setDialogMessage,
    deleteFileHelper,
    close,
    count,
    clearSelection,
}: IProps) {
    const deduplicateContext = useContext(DeduplicateContext);

    const trashHandler = () =>
        setDialogMessage({
            title: constants.CONFIRM_DELETE,
            content: constants.TRASH_MESSAGE,
            staticBackdrop: true,
            proceed: {
                action: deleteFileHelper,
                text: constants.MOVE_TO_TRASH,
                variant: 'danger',
            },
            close: { text: constants.CANCEL },
        });

    return (
        <SelectionBar>
            <SelectionContainer>
                {count ? (
                    <IconButton onClick={clearSelection}>
                        <CloseIcon />
                    </IconButton>
                ) : (
                    <IconButton onClick={close}>
                        <LeftArrow />
                    </IconButton>
                )}
                <div>
                    {count} {constants.SELECTED}
                </div>
            </SelectionContainer>
            <input
                type="checkbox"
                style={{
                    width: '1em',
                    height: '1em',
                }}
                value={
                    deduplicateContext.clubSameTimeFilesOnly ? 'true' : 'false'
                }
                onChange={() => {
                    deduplicateContext.setClubSameTimeFilesOnly(
                        !deduplicateContext.clubSameTimeFilesOnly
                    );
                }}></input>
            <CheckboxText>{constants.CLUB_BY_CAPTURE_TIME}</CheckboxText>
            <div>
                <VerticalLine />
            </div>
            <IconWithMessage message={constants.DELETE}>
                <IconButton onClick={trashHandler}>
                    <DeleteIcon />
                </IconButton>
            </IconWithMessage>
        </SelectionBar>
    );
}
