import { DeadCenter } from 'pages/gallery';
import React from 'react';
import { Form } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import { PLAN_PERIOD } from '.';
export function PeriodToggler({ planPeriod, togglePeriod }) {
    return (
        <DeadCenter>
            <div
                style={{
                    display: 'flex',
                }}>
                <span
                    className="bold-text"
                    style={{
                        fontSize: '16px',
                    }}>
                    {constants.MONTHLY}
                </span>

                <Form.Switch
                    checked={planPeriod === PLAN_PERIOD.YEAR}
                    id="plan-period-toggler"
                    style={{
                        margin: '-4px 0 20px 15px',
                        fontSize: '10px',
                    }}
                    className="custom-switch-md"
                    onChange={togglePeriod}
                />
                <span
                    className="bold-text"
                    style={{
                        fontSize: '16px',
                    }}>
                    {constants.YEARLY}
                </span>
            </div>
        </DeadCenter>
    );
}
