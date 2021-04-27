import { selectedState } from 'pages/gallery';
import { Chip } from 'pages/gallery/components/Collections';
import React from 'react';
import { Navbar, Nav } from 'react-bootstrap';
import { deleteFiles } from 'services/fileService';
import { SetDialogMessage } from 'utils/billingUtil';
import constants from 'utils/strings/constants';

interface Props {
    selected: selectedState;
    clearSelection: () => void;
    showCollectionSelectorView: () => void;
    setDialogMessage: SetDialogMessage;
    syncWithRemote: () => Promise<void>;
}
const OptionBar = (props: Props) => {
    if (props.selected.count === 0) {
        return <div />;
    }
    return (
        <Navbar>
            <Nav
                className="mr-auto"
                style={{
                    width: '52%',
                    margin: 'auto',
                    height: '32px',
                    color: 'white',
                }}
            >
                <Chip active={true} onClick={props.clearSelection}>
                    <span>close</span>
                </Chip>
                <Chip active={true}>
                    <span>{props.selected.count} selected</span>
                </Chip>
                <Chip active={true} onClick={props.showCollectionSelectorView}>
                    <span>Add to collection</span>
                </Chip>
                <Chip
                    active={true}
                    onClick={() =>
                        props.setDialogMessage({
                            title: constants.CONFIRM_DELETE_FILE,
                            content: constants.DELETE_FILE_MESSAGE,
                            staticBackdrop: true,
                            proceed: {
                                action: deleteFiles.bind(
                                    null,
                                    props.selected,
                                    props.clearSelection,
                                    props.syncWithRemote
                                ),
                                text: constants.DELETE,
                                variant: 'danger',
                            },
                            close: { text: constants.CANCEL },
                        })
                    }
                >
                    <span>delete</span>
                </Chip>
            </Nav>
        </Navbar>
    );
};

export default OptionBar;
