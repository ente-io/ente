import React from 'react';
import { Button } from 'react-bootstrap';
import { FIX_STATE } from '.';
import constants from 'utils/strings/constants';

export default function FixCreationTimeFooter({
    fixState,
    startFix,
    ...props
}) {
    return (
        fixState !== FIX_STATE.RUNNING && (
            <div
                style={{
                    width: '100%',
                    display: 'flex',
                    marginTop: '30px',
                    justifyContent: 'space-around',
                }}>
                {(fixState === FIX_STATE.NOT_STARTED ||
                    fixState === FIX_STATE.COMPLETED_WITH_ERRORS) && (
                    <Button
                        block
                        variant={'outline-secondary'}
                        onClick={() => {
                            props.hide();
                        }}>
                        {constants.CANCEL}
                    </Button>
                )}
                {fixState === FIX_STATE.COMPLETED && (
                    <Button
                        block
                        variant={'outline-secondary'}
                        onClick={props.hide}>
                        {constants.CLOSE}
                    </Button>
                )}
                {(fixState === FIX_STATE.NOT_STARTED ||
                    fixState === FIX_STATE.COMPLETED_WITH_ERRORS) && (
                    <>
                        <div style={{ width: '30px' }} />

                        <Button
                            block
                            variant={'outline-success'}
                            onClick={startFix}>
                            {constants.FIX_CREATION_TIME}
                        </Button>
                    </>
                )}
            </div>
        )
    );
}
