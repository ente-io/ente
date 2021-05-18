import { Formik } from 'formik';
import React from 'react';
import { Form } from 'react-bootstrap';
import styled from 'styled-components';
import constants from 'utils/strings/constants';
import * as Yup from 'yup';

const Wrapper = styled.div<{ open: boolean }>`
    background-color: #111;
    color: #fff;
    min-height: 64px;
    align-items: center;
    box-shadow: 0 0 5px rgba(0, 0, 0, 0.7);
    margin-bottom: 10px;
    position: fixed;
    top: 0;
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 200;
    padding: 0 20%;
    display: ${(props) => (props.open ? 'flex' : 'none')};
`;

interface formValues {
    searchPhrase: string;
}
interface Props {
    open: boolean;
    setOpen: (value) => void;
}
export default function SearchBar(props: Props) {
    return (
        <Wrapper open={props.open}>
            <div style={{ flex: 1, margin: '10px' }}>
                <Formik<formValues>
                    initialValues={{ searchPhrase: '' }}
                    onSubmit={() => console.log('search attempted')}
                    validationSchema={Yup.object().shape({
                        searchPhrase: Yup.string().required(constants.REQUIRED),
                    })}
                    validateOnChange={false}
                    validateOnBlur={false}
                >
                    {({
                        values,
                        touched,
                        errors,
                        handleChange,
                        handleSubmit,
                    }) => (
                        <Form noValidate onSubmit={handleSubmit}>
                            <Form.Control
                                type={'search'}
                                placeholder={'search your photos'}
                                value={values.searchPhrase}
                                onChange={handleChange('searchPhrase')}
                                isInvalid={Boolean(
                                    touched.searchPhrase && errors.searchPhrase
                                )}
                            />
                        </Form>
                    )}
                </Formik>
            </div>
            <div
                style={{
                    margin: '0',
                    display: 'flex',
                    alignItems: 'center',
                    cursor: 'pointer',
                }}
                onClick={() => props.setOpen(false)}
            >
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    height={25}
                    viewBox={`0 0 25 25`}
                    width={25}
                >
                    <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"></path>
                </svg>
            </div>
        </Wrapper>
    );
}
