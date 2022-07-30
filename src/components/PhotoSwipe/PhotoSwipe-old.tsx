export {};
// import React, { useContext, useEffect, useRef, useState } from 'react';
// import Photoswipe from 'photoswipe';
// import PhotoswipeUIDefault from 'photoswipe/dist/photoswipe-ui-default';
// import classnames from 'classnames';
// import FavButton from 'components/FavButton';
// import {
//     addToFavorites,
//     removeFromFavorites,
// } from 'services/collectionService';
// import { updatePublicMagicMetadata } from 'services/fileService';
// import { EnteFile } from 'types/file';
// import constants from 'utils/strings/constants';
// import exifr from 'exifr';
// import Modal from 'react-bootstrap/Modal';
// import Button from 'react-bootstrap/Button';
// import styled from 'styled-components';
// import events from './events';
// import {
//     changeFileCreationTime,
//     changeFileName,
//     downloadFile,
//     formatDateTime,
//     splitFilenameAndExtension,
//     updateExistingFilePubMetadata,
// } from 'utils/file';
// import { Col, Form, FormCheck, FormControl } from 'react-bootstrap';
// import { prettyPrintExif } from 'utils/exif';
// import EditIcon from 'components/icons/EditIcon';
// import {
//     FlexWrapper,
//     FreeFlowText,
//     IconButton,
//     Label,
//     Row,
//     Value,
// } from 'components/Container';
// import { logError } from 'utils/sentry';

// import CloseIcon from 'components/icons/CloseIcon';
// import TickIcon from 'components/icons/TickIcon';
// import {
//     PhotoPeopleList,
//     UnidentifiedFaces,
// } from 'components/MachineLearning/PeopleList';
// import { Formik } from 'formik';
// import * as Yup from 'yup';
// import EnteSpinner from 'components/EnteSpinner';
// import EnteDateTimePicker from 'components/EnteDateTimePicker';
// // import { AppContext } from 'pages/_app';

// import { MAX_EDITED_FILE_NAME_LENGTH } from 'constants/file';
// import { sleep } from 'utils/common';
// import { PublicCollectionGalleryContext } from 'utils/publicCollectionGallery';
// import { GalleryContext } from 'pages/gallery';
// import { ObjectLabelList } from 'components/MachineLearning/ObjectList';
// import { WordList } from 'components/MachineLearning/WordList';
// import MLServiceFileInfoButton from 'components/MachineLearning/MLServiceFileInfoButton';

// const SmallLoadingSpinner = () => (
//     <EnteSpinner
//         style={{
//             width: '20px',
//             height: '20px',
//         }}
//     />
// );
// interface Iprops {
//     isOpen: boolean;
//     items: EnteFile[];
//     currentIndex?: number;
//     onClose?: (needUpdate: boolean) => void;
//     gettingData: (instance: any, index: number, item: EnteFile) => void;
//     id?: string;
//     className?: string;
//     favItemIds: Set<number>;
//     isSharedCollection: boolean;
//     isTrashCollection: boolean;
// }

// const LegendContainer = styled.div`
//     display: flex;
//     justify-content: space-between;
// `;

// const Legend = styled.span`
//     font-size: 20px;
//     color: #ddd;
//     display: inline;
// `;

// const Pre = styled.pre`
//     color: #aaa;
//     padding: 7px 15px;
// `;

// const renderInfoItem = (label: string, value: string | JSX.Element) => (
//     <Row>
//         <Label width="30%">{label}</Label>
//         <Value width="70%">{value}</Value>
//     </Row>
// );

// function RenderCreationTime({
//     shouldDisableEdits,
//     file,
//     scheduleUpdate,
// }: {
//     shouldDisableEdits: boolean;
//     file: EnteFile;
//     scheduleUpdate: () => void;
// }) {
//     const [loading, setLoading] = useState(false);
//     const originalCreationTime = new Date(file?.metadata.creationTime / 1000);
//     const [isInEditMode, setIsInEditMode] = useState(false);

//     const [pickedTime, setPickedTime] = useState(originalCreationTime);

//     const openEditMode = () => setIsInEditMode(true);
//     const closeEditMode = () => setIsInEditMode(false);

//     const saveEdits = async () => {
//         try {
//             setLoading(true);
//             if (isInEditMode && file) {
//                 const unixTimeInMicroSec = pickedTime.getTime() * 1000;
//                 if (unixTimeInMicroSec === file?.metadata.creationTime) {
//                     closeEditMode();
//                     return;
//                 }
//                 let updatedFile = await changeFileCreationTime(
//                     file,
//                     unixTimeInMicroSec
//                 );
//                 updatedFile = (
//                     await updatePublicMagicMetadata([updatedFile])
//                 )[0];
//                 updateExistingFilePubMetadata(file, updatedFile);
//                 scheduleUpdate();
//             }
//         } catch (e) {
//             logError(e, 'failed to update creationTime');
//         } finally {
//             closeEditMode();
//             setLoading(false);
//         }
//     };
//     const discardEdits = () => {
//         setPickedTime(originalCreationTime);
//         closeEditMode();
//     };
//     const handleChange = (newDate: Date) => {
//         if (newDate instanceof Date) {
//             setPickedTime(newDate);
//         }
//     };
//     return (
//         <>
//             <Row>
//                 <Label width="30%">{constants.CREATION_TIME}</Label>
//                 <Value width={isInEditMode ? '50%' : '60%'}>
//                     {isInEditMode ? (
//                         <EnteDateTimePicker
//                             loading={loading}
//                             isInEditMode={isInEditMode}
//                             pickedTime={pickedTime}
//                             handleChange={handleChange}
//                         />
//                     ) : (
//                         formatDateTime(pickedTime)
//                     )}
//                 </Value>
//                 <Value
//                     width={isInEditMode ? '20%' : '10%'}
//                     style={{ cursor: 'pointer', marginLeft: '10px' }}>
//                     {!shouldDisableEdits &&
//                         (!isInEditMode ? (
//                             <IconButton onClick={openEditMode}>
//                                 <EditIcon />
//                             </IconButton>
//                         ) : (
//                             <>
//                                 <IconButton onClick={saveEdits}>
//                                     {loading ? (
//                                         <SmallLoadingSpinner />
//                                     ) : (
//                                         <TickIcon />
//                                     )}
//                                 </IconButton>
//                                 <IconButton onClick={discardEdits}>
//                                     <CloseIcon />
//                                 </IconButton>
//                             </>
//                         ))}
//                 </Value>
//             </Row>
//         </>
//     );
// }
// const getFileTitle = (filename, extension) => {
//     if (extension) {
//         return filename + '.' + extension;
//     } else {
//         return filename;
//     }
// };
// interface formValues {
//     filename: string;
// }

// const FileNameEditForm = ({ filename, saveEdits, discardEdits, extension }) => {
//     const [loading, setLoading] = useState(false);

//     const onSubmit = async (values: formValues) => {
//         try {
//             setLoading(true);
//             await saveEdits(values.filename);
//         } finally {
//             setLoading(false);
//         }
//     };
//     return (
//         <Formik<formValues>
//             initialValues={{ filename }}
//             validationSchema={Yup.object().shape({
//                 filename: Yup.string()
//                     .required(constants.REQUIRED)
//                     .max(
//                         MAX_EDITED_FILE_NAME_LENGTH,
//                         constants.FILE_NAME_CHARACTER_LIMIT
//                     ),
//             })}
//             validateOnBlur={false}
//             onSubmit={onSubmit}>
//             {({ values, errors, handleChange, handleSubmit }) => (
//                 <Form noValidate onSubmit={handleSubmit}>
//                     <Form.Row>
//                         <Form.Group
//                             bsPrefix="ente-form-group"
//                             as={Col}
//                             xs={extension ? 7 : 8}>
//                             <Form.Control
//                                 as="textarea"
//                                 placeholder={constants.FILE_NAME}
//                                 value={values.filename}
//                                 onChange={handleChange('filename')}
//                                 isInvalid={Boolean(errors.filename)}
//                                 autoFocus
//                                 disabled={loading}
//                             />
//                             <FormControl.Feedback
//                                 type="invalid"
//                                 style={{ textAlign: 'center' }}>
//                                 {errors.filename}
//                             </FormControl.Feedback>
//                         </Form.Group>
//                         {extension && (
//                             <Form.Group
//                                 bsPrefix="ente-form-group"
//                                 as={Col}
//                                 xs={1}
//                                 controlId="formHorizontalFileName">
//                                 <FlexWrapper style={{ padding: '5px' }}>
//                                     {`.${extension}`}
//                                 </FlexWrapper>
//                             </Form.Group>
//                         )}
//                         <Form.Group bsPrefix="ente-form-group" as={Col} xs={2}>
//                             <Value width={'16.67%'}>
//                                 <IconButton type="submit" disabled={loading}>
//                                     {loading ? (
//                                         <SmallLoadingSpinner />
//                                     ) : (
//                                         <TickIcon />
//                                     )}
//                                 </IconButton>
//                                 <IconButton
//                                     onClick={discardEdits}
//                                     disabled={loading}>
//                                     <CloseIcon />
//                                 </IconButton>
//                             </Value>
//                         </Form.Group>
//                     </Form.Row>
//                 </Form>
//             )}
//         </Formik>
//     );
// };

// function RenderFileName({
//     shouldDisableEdits,
//     file,
//     scheduleUpdate,
// }: {
//     shouldDisableEdits: boolean;
//     file: EnteFile;
//     scheduleUpdate: () => void;
// }) {
//     const originalTitle = file?.metadata.title;
//     const [isInEditMode, setIsInEditMode] = useState(false);
//     const [originalFileName, extension] =
//         splitFilenameAndExtension(originalTitle);
//     const [filename, setFilename] = useState(originalFileName);
//     const openEditMode = () => setIsInEditMode(true);
//     const closeEditMode = () => setIsInEditMode(false);

//     const saveEdits = async (newFilename: string) => {
//         try {
//             if (file) {
//                 if (filename === newFilename) {
//                     closeEditMode();
//                     return;
//                 }
//                 setFilename(newFilename);
//                 const newTitle = getFileTitle(newFilename, extension);
//                 let updatedFile = await changeFileName(file, newTitle);
//                 updatedFile = (
//                     await updatePublicMagicMetadata([updatedFile])
//                 )[0];
//                 updateExistingFilePubMetadata(file, updatedFile);
//                 scheduleUpdate();
//             }
//         } catch (e) {
//             logError(e, 'failed to update file name');
//         } finally {
//             closeEditMode();
//         }
//     };
//     return (
//         <>
//             <Row>
//                 <Label width="30%">{constants.FILE_NAME}</Label>
//                 {!isInEditMode ? (
//                     <>
//                         <Value width="60%">
//                             <FreeFlowText>
//                                 {getFileTitle(filename, extension)}
//                             </FreeFlowText>
//                         </Value>
//                         {!shouldDisableEdits && (
//                             <Value
//                                 width="10%"
//                                 style={{
//                                     cursor: 'pointer',
//                                     marginLeft: '10px',
//                                 }}>
//                                 <IconButton onClick={openEditMode}>
//                                     <EditIcon />
//                                 </IconButton>
//                             </Value>
//                         )}
//                     </>
//                 ) : (
//                     <FileNameEditForm
//                         extension={extension}
//                         filename={filename}
//                         saveEdits={saveEdits}
//                         discardEdits={closeEditMode}
//                     />
//                 )}
//             </Row>
//         </>
//     );
// }
// function ExifData(props: { exif: any }) {
//     const { exif } = props;
//     const [showAll, setShowAll] = useState(false);

//     const changeHandler = (e: React.ChangeEvent<HTMLInputElement>) => {
//         setShowAll(e.target.checked);
//     };

//     const renderAllValues = () => <Pre>{exif.raw}</Pre>;

//     const renderSelectedValues = () => (
//         <>
//             {exif?.Make &&
//                 exif?.Model &&
//                 renderInfoItem(constants.DEVICE, `${exif.Make} ${exif.Model}`)}
//             {exif?.ImageWidth &&
//                 exif?.ImageHeight &&
//                 renderInfoItem(
//                     constants.IMAGE_SIZE,
//                     `${exif.ImageWidth} x ${exif.ImageHeight}`
//                 )}
//             {exif?.Flash && renderInfoItem(constants.FLASH, exif.Flash)}
//             {exif?.FocalLength &&
//                 renderInfoItem(
//                     constants.FOCAL_LENGTH,
//                     exif.FocalLength.toString()
//                 )}
//             {exif?.ApertureValue &&
//                 renderInfoItem(
//                     constants.APERTURE,
//                     exif.ApertureValue.toString()
//                 )}
//             {exif?.ISOSpeedRatings &&
//                 renderInfoItem(constants.ISO, exif.ISOSpeedRatings.toString())}
//         </>
//     );

//     return (
//         <>
//             <LegendContainer>
//                 <Legend>{constants.EXIF}</Legend>
//                 <FormCheck>
//                     <FormCheck.Label>
//                         <FormCheck.Input onChange={changeHandler} />
//                         {constants.SHOW_ALL}
//                     </FormCheck.Label>
//                 </FormCheck>
//             </LegendContainer>
//             {showAll ? renderAllValues() : renderSelectedValues()}
//         </>
//     );
// }

// function InfoModal({
//     shouldDisableEdits,
//     showInfo,
//     handleCloseInfo,
//     items,
//     photoSwipe,
//     metadata,
//     exif,
//     scheduleUpdate,
// }) {
//     // const appContext = useContext(AppContext);
//     const [updateMLDataIndex, setUpdateMLDataIndex] = useState(0);

//     return (
//         <Modal show={showInfo} onHide={handleCloseInfo}>
//             <Modal.Header closeButton>
//                 <Modal.Title>{constants.INFO}</Modal.Title>
//             </Modal.Header>
//             <Modal.Body>
//                 <div>
//                     <Legend>{constants.METADATA}</Legend>
//                 </div>
//                 {renderInfoItem(
//                     constants.FILE_ID,
//                     items[photoSwipe?.getCurrentIndex()]?.id
//                 )}
//                 {metadata?.title && (
//                     <RenderFileName
//                         shouldDisableEdits={shouldDisableEdits}
//                         file={items[photoSwipe?.getCurrentIndex()]}
//                         scheduleUpdate={scheduleUpdate}
//                     />
//                 )}
//                 {metadata?.creationTime && (
//                     <RenderCreationTime
//                         shouldDisableEdits={shouldDisableEdits}
//                         file={items[photoSwipe?.getCurrentIndex()]}
//                         scheduleUpdate={scheduleUpdate}
//                     />
//                 )}
//                 {metadata?.modificationTime &&
//                     renderInfoItem(
//                         constants.UPDATED_ON,
//                         formatDateTime(metadata.modificationTime / 1000)
//                     )}
//                 {metadata?.longitude > 0 &&
//                     metadata?.longitude > 0 &&
//                     renderInfoItem(
//                         constants.LOCATION,
//                         <a
//                             href={`https://www.openstreetmap.org/?mlat=${metadata.latitude}&mlon=${metadata.longitude}#map=15/${metadata.latitude}/${metadata.longitude}`}
//                             target="_blank"
//                             rel="noopener noreferrer">
//                             {constants.SHOW_MAP}
//                         </a>
//                     )}
//                 {/* {appContext.mlSearchEnabled && ( */}
//                 <>
//                     <div>
//                         <Legend>{constants.PEOPLE}</Legend>
//                     </div>
//                     <PhotoPeopleList
//                         file={items[photoSwipe?.getCurrentIndex()]}
//                         updateMLDataIndex={updateMLDataIndex}
//                     />
//                     <div>
//                         <Legend>{constants.UNIDENTIFIED_FACES}</Legend>
//                     </div>
//                     <UnidentifiedFaces
//                         file={items[photoSwipe?.getCurrentIndex()]}
//                         updateMLDataIndex={updateMLDataIndex}
//                     />
//                     <div>
//                         <Legend>{constants.OBJECTS}</Legend>
//                         <ObjectLabelList
//                             file={items[photoSwipe?.getCurrentIndex()]}
//                             updateMLDataIndex={updateMLDataIndex}
//                         />
//                     </div>
//                     <div>
//                         <Legend>{constants.TEXT}</Legend>
//                         <WordList
//                             file={items[photoSwipe?.getCurrentIndex()]}
//                             updateMLDataIndex={updateMLDataIndex}
//                         />
//                     </div>
//                     <MLServiceFileInfoButton
//                         file={items[photoSwipe?.getCurrentIndex()]}
//                         updateMLDataIndex={updateMLDataIndex}
//                         setUpdateMLDataIndex={setUpdateMLDataIndex}
//                     />
//                 </>
//                 {/* )} */}
//                 {exif && (
//                     <>
//                         <ExifData exif={exif} />
//                     </>
//                 )}
//             </Modal.Body>
//             <Modal.Footer>
//                 <Button variant="outline-secondary" onClick={handleCloseInfo}>
//                     {constants.CLOSE}
//                 </Button>
//             </Modal.Footer>
//         </Modal>
//     );
// }

// function PhotoSwipe(props: Iprops) {
//     const pswpElement = useRef<HTMLDivElement>();
//     const [photoSwipe, setPhotoSwipe] = useState<Photoswipe<any>>();

//     const { isOpen, items } = props;
//     const [isFav, setIsFav] = useState(false);
//     const [showInfo, setShowInfo] = useState(false);
//     const [metadata, setMetaData] = useState<EnteFile['metadata']>(null);
//     const [exif, setExif] = useState<any>(null);
//     const needUpdate = useRef(false);
//     const publicCollectionGalleryContext = useContext(
//         PublicCollectionGalleryContext
//     );
//     const galleryContext = useContext(GalleryContext);

//     useEffect(() => {
//         if (!pswpElement) return;
//         if (isOpen) {
//             openPhotoSwipe();
//         }
//         if (!isOpen) {
//             closePhotoSwipe();
//         }
//         return () => {
//             closePhotoSwipe();
//         };
//     }, [isOpen]);

//     useEffect(() => {
//         updateItems(items);
//     }, [items]);

//     // useEffect(() => {
//     //     if (photoSwipe) {
//     //         photoSwipe.options.arrowKeys = !showInfo;
//     //         photoSwipe.options.escKey = !showInfo;
//     //     }
//     // }, [showInfo]);

//     function updateFavButton() {
//         setIsFav(isInFav(this?.currItem));
//     }

//     const openPhotoSwipe = () => {
//         const { items, currentIndex } = props;
//         const options = {
//             history: false,
//             maxSpreadZoom: 5,
//             index: currentIndex,
//             showHideOpacity: true,
//             getDoubleTapZoom(isMouseClick, item) {
//                 if (isMouseClick) {
//                     return 2.5;
//                 }
//                 // zoom to original if initial zoom is less than 0.7x,
//                 // otherwise to 1.5x, to make sure that double-tap gesture always zooms image
//                 return item.initialZoomLevel < 0.7 ? 1 : 1.5;
//             },
//             getThumbBoundsFn: (index) => {
//                 try {
//                     const file = items[index];
//                     const ele = document.getElementById(`thumb-${file.id}`);
//                     if (ele) {
//                         const rect = ele.getBoundingClientRect();
//                         const pageYScroll =
//                             window.pageYOffset ||
//                             document.documentElement.scrollTop;
//                         return {
//                             x: rect.left,
//                             y: rect.top + pageYScroll,
//                             w: rect.width,
//                         };
//                     }
//                     return null;
//                 } catch (e) {
//                     return null;
//                 }
//             },
//         };
//         const photoSwipe = new Photoswipe(
//             pswpElement.current,
//             PhotoswipeUIDefault,
//             items,
//             options
//         );
//         events.forEach((event) => {
//             const callback = props[event];
//             if (callback || event === 'destroy') {
//                 photoSwipe.listen(event, function (...args) {
//                     if (callback) {
//                         args.unshift(this);
//                         callback(...args);
//                     }
//                     if (event === 'destroy') {
//                         handleClose();
//                     }
//                     if (event === 'close') {
//                         handleClose();
//                     }
//                 });
//             }
//         });
//         photoSwipe.listen('beforeChange', function () {
//             updateInfo.call(this);
//             updateFavButton.call(this);
//         });
//         photoSwipe.listen('resize', checkExifAvailable);
//         photoSwipe.init();
//         needUpdate.current = false;
//         setPhotoSwipe(photoSwipe);
//     };

//     const closePhotoSwipe = () => {
//         if (photoSwipe) photoSwipe.close();
//     };

//     const handleClose = () => {
//         const { onClose } = props;
//         if (typeof onClose === 'function') {
//             onClose(needUpdate.current);
//         }
//         const videoTags = document.getElementsByTagName('video');
//         for (const videoTag of videoTags) {
//             videoTag.pause();
//         }
//         handleCloseInfo();
//     };
//     const isInFav = (file) => {
//         const { favItemIds } = props;
//         if (favItemIds && file) {
//             return favItemIds.has(file.id);
//         }
//         return false;
//     };

//     const onFavClick = async (file) => {
//         const { favItemIds } = props;
//         if (!isInFav(file)) {
//             favItemIds.add(file.id);
//             addToFavorites(file);
//             setIsFav(true);
//         } else {
//             favItemIds.delete(file.id);
//             removeFromFavorites(file);
//             setIsFav(false);
//         }
//         needUpdate.current = true;
//     };

//     const updateItems = (items = []) => {
//         if (photoSwipe) {
//             photoSwipe.items.length = 0;
//             items.forEach((item) => {
//                 photoSwipe.items.push(item);
//             });
//             photoSwipe.invalidateCurrItems();
//             // photoSwipe.updateSize(true);
//         }
//     };

//     const checkExifAvailable = async () => {
//         setExif(null);
//         await sleep(100);
//         try {
//             const img: HTMLImageElement = document.querySelector(
//                 '.pswp__img:not(.pswp__img--placeholder)'
//             );
//             if (img) {
//                 const exifData = await exifr.parse(img);
//                 if (!exifData) {
//                     return;
//                 }
//                 exifData.raw = prettyPrintExif(exifData);
//                 setExif(exifData);
//             }
//         } catch (e) {
//             logError(e, 'exifr parsing failed');
//         }
//     };

//     function updateInfo() {
//         const file: EnteFile = this?.currItem;
//         if (file?.metadata) {
//             setMetaData(file.metadata);
//             setExif(null);
//             checkExifAvailable();
//         }
//     }

//     const handleCloseInfo = () => {
//         setShowInfo(false);
//     };
//     const handleOpenInfo = () => {
//         setShowInfo(true);
//     };

//     const downloadFileHelper = async (file) => {
//         galleryContext.startLoading();
//         await downloadFile(
//             file,
//             publicCollectionGalleryContext.accessedThroughSharedURL,
//             publicCollectionGalleryContext.token
//         );

//         galleryContext.finishLoading();
//     };
//     const scheduleUpdate = () => (needUpdate.current = true);
//     const { id } = props;
//     let { className } = props;
//     className = classnames(['pswp', className]).trim();
//     return (
//         <>
//             <div
//                 id={id}
//                 className={className}
//                 tabIndex={Number('-1')}
//                 role="dialog"
//                 aria-hidden="true"
//                 ref={pswpElement}>
//                 <div className="pswp__bg" />
//                 <div className="pswp__scroll-wrap">
//                     <div className="pswp__container">
//                         <div className="pswp__item" />
//                         <div className="pswp__item" />
//                         <div className="pswp__item" />
//                     </div>
//                     <div className="pswp__ui pswp__ui--hidden">
//                         <div className="pswp__top-bar">
//                             <div className="pswp__counter" />

//                             <button
//                                 className="pswp__button pswp__button--close"
//                                 title={constants.CLOSE}
//                             />

//                             <button
//                                 className="pswp-custom download-btn"
//                                 title={constants.DOWNLOAD}
//                                 onClick={() =>
//                                     downloadFileHelper(photoSwipe.currItem)
//                                 }
//                             />

//                             <button
//                                 className="pswp__button pswp__button--fs"
//                                 title={constants.TOGGLE_FULLSCREEN}
//                             />
//                             <button
//                                 className="pswp__button pswp__button--zoom"
//                                 title={constants.ZOOM_IN_OUT}
//                             />
//                             {!props.isSharedCollection &&
//                                 !props.isTrashCollection && (
//                                     <FavButton
//                                         size={44}
//                                         isClick={isFav}
//                                         onClick={() => {
//                                             onFavClick(photoSwipe?.currItem);
//                                         }}
//                                     />
//                                 )}
//                             <button
//                                 className="pswp-custom info-btn"
//                                 title={constants.INFO}
//                                 onClick={handleOpenInfo}
//                             />
//                             <div className="pswp__preloader">
//                                 <div className="pswp__preloader__icn">
//                                     <div className="pswp__preloader__cut">
//                                         <div className="pswp__preloader__donut" />
//                                     </div>
//                                 </div>
//                             </div>
//                         </div>
//                         <div className="pswp__share-modal pswp__share-modal--hidden pswp__single-tap">
//                             <div className="pswp__share-tooltip" />
//                         </div>
//                         <button
//                             className="pswp__button pswp__button--arrow--left"
//                             title={constants.PREVIOUS}
//                         />
//                         <button
//                             className="pswp__button pswp__button--arrow--right"
//                             title={constants.NEXT}
//                         />
//                         <div className="pswp__caption">
//                             <div />
//                         </div>
//                     </div>
//                 </div>
//             </div>
//             <InfoModal
//                 shouldDisableEdits={props.isSharedCollection}
//                 showInfo={showInfo}
//                 handleCloseInfo={handleCloseInfo}
//                 items={items}
//                 photoSwipe={photoSwipe}
//                 metadata={metadata}
//                 exif={exif}
//                 scheduleUpdate={scheduleUpdate}
//             />
//         </>
//     );
// }

// export default PhotoSwipe;
