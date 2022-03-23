import { IconButton } from 'components/Container';
import CloseIcon from 'components/icons/CloseIcon';
import DeleteIcon from 'components/icons/DeleteIcon';
import { SetDialogMessage } from 'components/MessageDialog';
import Navbar from 'components/Navbar';
import React from 'react';
import { OverlayTrigger } from 'react-bootstrap';
import styled from 'styled-components';
import constants from 'utils/strings/constants';

interface Props {
    setDialogMessage: SetDialogMessage;
    deleteFileHelper: () => void;
    count: number;
    clearSelection: () => void;
    clubByTime: boolean;
    setClubByTime: (clubByTime: boolean) => void;
}

const SelectionBar = styled(Navbar)`
    position: fixed;
    top: 0;
    color: #fff;
    z-index: 1001;
    width: 100%;
    padding: 0 16px;
`;

const SelectionContainer = styled.div`
    flex: 1;
    align-items: center;
    display: flex;
`;

interface IconWithMessageProps {
    children?: any;
    message: string;
}
export const IconWithMessage = (props: IconWithMessageProps) => (
    <OverlayTrigger
        placement="bottom"
        overlay={<p style={{ zIndex: 1002 }}>{props.message}</p>}>
        {props.children}
    </OverlayTrigger>
);

const SelectedFileOptions = ({
    setDialogMessage,
    deleteFileHelper,
    count,
    clearSelection,
    clubByTime,
    setClubByTime,
}: Props) => {
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
                <IconButton onClick={clearSelection}>
                    <CloseIcon />
                </IconButton>
                <div>
                    {count} {constants.SELECTED}
                </div>
            </SelectionContainer>
            <>
                <input
                    type="checkbox"
                    style={{
                        width: '1em',
                        height: '1em',
                    }}
                    value={clubByTime ? 'true' : 'false'}
                    onChange={() => {
                        setClubByTime(!clubByTime);
                    }}></input>
                <div
                    style={{
                        marginLeft: '0.5em',
                    }}>
                    {constants.CLUB_BY_CAPTURE_TIME}
                </div>
                <IconWithMessage message={constants.DELETE}>
                    <IconButton onClick={trashHandler}>
                        <DeleteIcon />
                    </IconButton>
                </IconWithMessage>
            </>
        </SelectionBar>
    );
};

export default SelectedFileOptions;
