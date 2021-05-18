import { Formik } from 'formik';
import { SetCollections, SetFiles } from 'pages/gallery';
import React from 'react';
import { Form } from 'react-bootstrap';
import styled from 'styled-components';
import constants from 'utils/strings/constants';
import * as Yup from 'yup';
import { File } from 'services/fileService';
import * as chrono from 'chrono-node';
import { getNonEmptyCollections } from 'services/collectionService';

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
    isOpen: boolean;
    setOpen: (value) => void;
    loadingBar: any;
    files: File[];
    setFiles: SetFiles;
    setCollections: SetCollections;
    restoreGallery: () => Promise<void>;
}
export default function SearchBar(props: Props) {
    const isSameDay = (baseDate) => (compareDate) => {
        return (
            baseDate.getMonth() === compareDate.getMonth() &&
            baseDate.getDate() === compareDate.getDate()
        );
    };

    const searchFiles = async (values: formValues) => {
        const searchDate = chrono.parseDate(values.searchPhrase);
        console.log(searchDate);
        const searchDateComparer = isSameDay(searchDate);
        const filesWithSameDate = props.files.filter((file) => {
            if (
                searchDateComparer(new Date(file.metadata.creationTime / 1000))
            ) {
                console.log(new Date(file.metadata.creationTime / 1000));
                return true;
            }
            return false;
        });
        props.setFiles(filesWithSameDate);
        props.setCollections((collection) =>
            getNonEmptyCollections(collection, filesWithSameDate)
        );
    };
    const closeSearchBar = async ({ resetForm }) => {
        props.setOpen(false);
        resetForm();
        await props.restoreGallery();
    };
    return (
        <Wrapper open={props.isOpen}>
            <Formik<formValues>
                initialValues={{ searchPhrase: '' }}
                onSubmit={searchFiles}
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
                    resetForm,
                }) => (
                    <>
                        <div
                            style={{
                                flex: 1,
                                maxWidth: '700px',
                                margin: '10px',
                            }}
                        >
                            <Form noValidate onSubmit={handleSubmit}>
                                <Form.Control
                                    type={'search'}
                                    placeholder={'search your photos'}
                                    value={values.searchPhrase}
                                    onChange={handleChange('searchPhrase')}
                                    isInvalid={Boolean(
                                        touched.searchPhrase &&
                                            errors.searchPhrase
                                    )}
                                />
                            </Form>
                        </div>
                        <div
                            style={{
                                margin: '0',
                                display: 'flex',
                                alignItems: 'center',
                                cursor: 'pointer',
                            }}
                            onClick={async () =>
                                await closeSearchBar({ resetForm })
                            }
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
                    </>
                )}
            </Formik>
        </Wrapper>
    );
}
