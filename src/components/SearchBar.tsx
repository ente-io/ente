import { Formik } from 'formik';
import { SetCollections, SetFiles } from 'pages/gallery';
import React, { useEffect, useState } from 'react';
import { Form } from 'react-bootstrap';
import styled from 'styled-components';
import constants from 'utils/strings/constants';
import * as Yup from 'yup';
import { File, getLocalFiles } from 'services/fileService';
import * as chrono from 'chrono-node';
import {
    Collection,
    getLocalCollections,
    getNonEmptyCollections,
} from 'services/collectionService';
import { searchLocation } from 'services/searchService';
import { getFilesInsideBbox } from 'utils/search';

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
    setFiles: SetFiles;
    setCollections: SetCollections;
}
export default function SearchBar(props: Props) {
    const [allFiles, setAllFiles] = useState<File[]>([]);
    const [allCollections, setAllCollections] = useState<Collection[]>([]);

    useEffect(() => {
        const main = async () => {
            setAllFiles(await getLocalFiles());
            setAllCollections(await getLocalCollections());
        };
        main();
    }, []);
    const isSameDay = (baseDate) => (compareDate) => {
        return (
            baseDate.getMonth() === compareDate.getMonth() &&
            baseDate.getDate() === compareDate.getDate()
        );
    };

    const searchFiles = async (values: formValues) => {
        props.loadingBar.continuousStart();
        let resultFiles: File[] = [];
        const searchDate = chrono.parseDate(values.searchPhrase);
        if (searchDate != null) {
            const searchDateComparer = isSameDay(searchDate);
            const filesWithSameDate = allFiles.filter((file) =>
                searchDateComparer(new Date(file.metadata.creationTime / 1000))
            );
            resultFiles = filesWithSameDate;
        } else {
            const bbox = await searchLocation(values.searchPhrase);
            if (bbox) {
                const filesAtLocation = getFilesInsideBbox(allFiles, bbox);
                resultFiles = filesAtLocation;
            }
        }
        props.setFiles(resultFiles);
        props.setCollections(
            getNonEmptyCollections(allCollections, resultFiles)
        );
        await new Promise((resolve) =>
            setTimeout(() => resolve(props.loadingBar.complete()), 100)
        );
    };
    const closeSearchBar = ({ resetForm }) => {
        props.setOpen(false);
        props.setFiles(allFiles);
        props.setCollections(allCollections);
        resetForm();
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
                            onClick={() => closeSearchBar({ resetForm })}
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
