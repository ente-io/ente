export {};

// import React, { useState, useEffect, useContext, ChangeEvent } from 'react';
// import { getData, LS_KEYS } from 'utils/storage/localStorage';
// import { useRouter } from 'next/router';
// import { ComlinkWorker } from 'utils/comlink';
// import { AppContext } from 'pages/_app';
// import { PAGES } from 'constants/pages';
// import * as Comlink from 'comlink';
// import { runningInBrowser } from 'utils/common';
// import TFJSImage from './TFJSImage';
// import {
//     Face,
//     MLDebugResult,
//     MLSyncConfig,
//     Person,
// } from 'types/machineLearning';
// import Tree from 'react-d3-tree';
// import MLFileDebugView from './MLFileDebugView';
// import mlWorkManager from 'services/machineLearning/mlWorkManager';
// // import { getAllFacesMap, mlLibraryStore } from 'utils/storage/mlStorage';
// import { getAllFacesFromMap, getAllPeople } from 'utils/machineLearning';
// import { FaceImagesRow, ImageBlobView, ImageCacheView } from './ImageViews';
// import mlIDbStorage from 'utils/storage/mlIDbStorage';
// import { getFaceCropBlobFromStorage } from 'utils/machineLearning/faceCrop';
// import { PeopleList } from './PeopleList';
// import { styled } from '@mui/material';

// import { RawNodeDatum } from 'react-d3-tree/lib/types/common';
// import { DebugInfo, mstToBinaryTree } from 'hdbscan';
// import { toD3Tree } from 'utils/machineLearning/clustering';
// import {
//     getMLSyncConfig,
//     getMLSyncJobConfig,
//     updateMLSyncConfig,
//     updateMLSyncJobConfig,
// } from 'utils/machineLearning/config';
// import { Button, Col, Container, Form, Row } from 'react-bootstrap';
// import { JobConfig } from 'types/common/job';
// import { ConfigEditor } from './ConfigEditor';
// import {
//     DEFAULT_ML_SYNC_CONFIG,
//     DEFAULT_ML_SYNC_JOB_CONFIG,
// } from 'constants/machineLearning/config';
// import { exportMlData, importMlData } from 'utils/machineLearning/mldataExport';
// import { FACE_CROPS_CACHE } from 'constants/cache';

// interface TSNEProps {
//     mlResult: MLDebugResult;
// }

// function TSNEPlot(props: TSNEProps) {
//     return (
//         <svg
//             width={props.mlResult.tsne.width + 40}
//             height={props.mlResult.tsne.height + 40}>
//             {props.mlResult.tsne.dataset.map((data, i) => (
//                 <foreignObject
//                     key={i}
//                     x={data.x - 20}
//                     y={data.y - 20}
//                     width={40}
//                     height={40}>
//                     <TFJSImage
//                         faceImage={props.mlResult.allFaces[i]?.faceImage}
//                         width={40}
//                         height={40}></TFJSImage>
//                 </foreignObject>
//             ))}
//         </svg>
//     );
// }

// const D3ImageContainer = styled('div')`
//     & > img {
//         width: 100%;
//         height: 100%;
//     }
// `;

// const renderForeignObjectNode = ({ nodeDatum, foreignObjectProps }) => (
//     <g>
//         <circle r={15}></circle>
//         {/* `foreignObject` requires width & height to be explicitly set. */}
//         <foreignObject {...foreignObjectProps}>
//             <div
//                 style={{
//                     border: '1px solid black',
//                     backgroundColor: '#dedede',
//                 }}>
//                 <h3 style={{ textAlign: 'center', color: 'black' }}>
//                     {nodeDatum.name}
//                 </h3>
//                 {!nodeDatum.children && nodeDatum.name && (
//                     <D3ImageContainer>
//                         <ImageCacheView
//                             url={nodeDatum.attributes.face.crop?.imageUrl}
//                             cacheName={FACE_CROPS_CACHE}
//                         />
//                     </D3ImageContainer>
//                 )}
//             </div>
//         </foreignObject>
//     </g>
// );

// const getFaceCrops = async (faces: Face[]) => {
//     const faceCropPromises = faces
//         .filter((f) => f?.crop)
//         .map((f) => getFaceCropBlobFromStorage(f.crop));
//     return Promise.all(faceCropPromises);
// };

// const ClusterFacesRow = styled(FaceImagesRow)`
//     display: flex;
//     max-width: 100%;
//     overflow: auto;
// `;

// const RowWithGap = styled(Row)`
//     justify-content: center;
//     & > * {
//         margin: 10px;
//     }
// `;

// export default function MLDebug() {
//     const [token, setToken] = useState<string>();
//     const [clusterFaceDistance] = useState<number>(0.4);
//     // const [minClusterSize, setMinClusterSize] = useState<number>(5);
//     // const [minFaceSize, setMinFaceSize] = useState<number>(32);
//     // const [batchSize, setBatchSize] = useState<number>(200);
//     const [maxFaceDistance] = useState<number>(0.5);
//     const [mlResult, setMlResult] = useState<MLDebugResult>({
//         allFaces: [],
//         clustersWithNoise: {
//             clusters: [],
//             noise: [],
//         },
//         tree: null,
//         tsne: null,
//     });

//     const [allPeople, setAllPeople] = useState<Array<Person>>([]);
//     const [clusters, setClusters] = useState<Array<Array<Blob>>>([]);
//     const [noiseFaces, setNoiseFaces] = useState<Array<Blob>>([]);
//     const [minProbability, setMinProbability] = useState<number>(0);
//     const [maxProbability, setMaxProbability] = useState<number>(1);
//     const [filteredFaces, setFilteredFaces] = useState<Array<Blob>>([]);
//     const [mstD3Tree, setMstD3Tree] = useState<RawNodeDatum>(null);
//     const [debugFile, setDebugFile] = useState<File>();

//     const router = useRouter();
//     const appContext = useContext(AppContext);

//     const getDedicatedMLWorker = (): ComlinkWorker => {
//         if (token) {
//             addLogLine('Toen present');

//         }
//         if (runningInBrowser()) {
//             addLogLine('initiating worker');
//             const worker = new Worker(
//                 new URL('worker/machineLearning.worker', import.meta.url),
//                 { name: 'ml-worker' }
//             );
//             addLogLine('initiated worker');
//             const comlink = Comlink.wrap(worker);
//             return { comlink, worker };
//         }
//     };
//     let MLWorker: ComlinkWorker;

//     useEffect(() => {
//         const user = getData(LS_KEYS.USER);
//         if (!user?.token) {
//             router.push(PAGES.ROOT);
//         } else {
//             setToken(user.token);
//         }
//         appContext.showNavBar(true);
//     }, []);

//     const onSync = async () => {
//         try {
//             if (!MLWorker) {
//                 MLWorker = getDedicatedMLWorker();
//                 addLogLine('initiated MLWorker');
//             }
//             const mlWorker = await new MLWorker.comlink();
//             const result = await mlWorker.sync(
//                 token,
//                 clusterFaceDistance,
//                 // minClusterSize,
//                 // minFaceSize,
//                 // batchSize,
//                 maxFaceDistance
//             );
//             setMlResult(result);
//         } catch (e) {
//             console.error(e);
//             throw e;
//         } finally {
//             // setTimeout(()=>{
//             //     addLogLine('terminating ml-worker');
//             MLWorker.worker.terminate();
//             // }, 30000);
//         }
//     };

//     const onStartMLSync = async () => {
//         mlWorkManager.startSyncJob();
//     };

//     const onStopMLSync = async () => {
//         mlWorkManager.stopSyncJob();
//     };

//     // for debug purpose, not a memory efficient implementation
//     const onExportMLData = async () => {
//         let mlDataZipHandle: FileSystemFileHandle;
//         try {
//             mlDataZipHandle = await showSaveFilePicker({
//                 suggestedName: `ente-mldata-${Date.now()}`,
//                 types: [
//                     {
//                         accept: {
//                             'application/zip': ['.zip'],
//                         },
//                     },
//                 ],
//             });
//         } catch (e) {
//             console.error(e);
//             return;
//         }

//         try {
//             const mlDataZipWritable = await mlDataZipHandle.createWritable();
//             await exportMlData(mlDataZipWritable);
//         } catch (e) {
//             console.error('Error while exporting: ', e);
//         }
//     };

//     const onImportMLData = async () => {
//         let mlDataZipHandle: FileSystemFileHandle;
//         try {
//             [mlDataZipHandle] = await showOpenFilePicker({
//                 types: [
//                     {
//                         accept: {
//                             'application/zip': ['.zip'],
//                         },
//                     },
//                 ],
//             });
//         } catch (e) {
//             console.error(e);
//             return;
//         }

//         try {
//             const mlDataZipFile = await mlDataZipHandle.getFile();
//             await importMlData(mlDataZipFile);
//         } catch (e) {
//             console.error('Error while importing: ', e);
//         }
//     };

//     const onClearPeopleIndex = async () => {
//         mlIDbStorage.setIndexVersion('people', 0);
//     };

//     const onDebugFile = async (event: ChangeEvent<HTMLInputElement>) => {
//         setDebugFile(event.target.files[0]);
//     };

//     const onLoadAllPeople = async () => {
//         const allPeople = await getAllPeople(100);
//         setAllPeople(allPeople);
//     };

//     const onLoadClusteringResults = async () => {
//         const mlLibraryData = await mlIDbStorage.getLibraryData();
//         const allFacesMap = await mlIDbStorage.getAllFacesMap();
//         const allFaces = getAllFacesFromMap(allFacesMap);

//         const clusterPromises = mlLibraryData?.faceClusteringResults?.clusters
//             .map((cluster) => cluster?.slice(0, 200).map((f) => allFaces[f]))
//             .map((faces) => getFaceCrops(faces));
//         setClusters(await Promise.all(clusterPromises));

//         const noiseFaces = mlLibraryData?.faceClusteringResults?.noise
//             ?.slice(0, 200)
//             .map((n) => allFaces[n]);
//         setNoiseFaces(await getFaceCrops(noiseFaces));

//         // TODO: disabling mst binary tree display for faces > 1000
//         // can enable once toD3Tree is non recursive
//         // and only important part of tree is retrieved
//         const clusteringDebugInfo: DebugInfo =
//             mlLibraryData?.faceClusteringResults['debugInfo'];
//         if (allFaces.length <= 1000 && clusteringDebugInfo) {
//             const mstBinaryTree = mstToBinaryTree(clusteringDebugInfo.mst);
//             const d3Tree = toD3Tree(mstBinaryTree, allFaces);
//             setMstD3Tree(d3Tree);
//         }
//     };

//     const showFilteredFaces = async () => {
//         addLogLine('Filtering with: ', minProbability, maxProbability);
//         const allFacesMap = await mlIDbStorage.getAllFacesMap();
//         const allFaces = getAllFacesFromMap(allFacesMap);
//         const filteredFaces = allFaces
//             .filter(
//                 (f) =>
//                     f.detection.probability >= minProbability &&
//                     f.detection.probability <= maxProbability
//             )
//             .slice(0, 200);
//         setFilteredFaces(await getFaceCrops(filteredFaces));
//     };

//     const nodeSize = { x: 180, y: 180 };
//     const foreignObjectProps = { width: 112, height: 150, x: -56 };

//     // TODO: Remove debug page or config editor from prod
//     return (
//         <Container>
//             {/* <div>ClusterFaceDistance: {clusterFaceDistance}</div>
//             <button onClick={() => setClusterFaceDistance(0.35)}>0.35</button>
//             <button onClick={() => setClusterFaceDistance(0.4)}>0.4</button>
//             <button onClick={() => setClusterFaceDistance(0.45)}>0.45</button>
//             <button onClick={() => setClusterFaceDistance(0.5)}>0.5</button>
//             <button onClick={() => setClusterFaceDistance(0.55)}>0.55</button>
//             <button onClick={() => setClusterFaceDistance(0.6)}>0.6</button>

//             <p></p> */}
//             <hr />
//             <Row>
//                 <Col>
//                     <ConfigEditor
//                         name="ML Sync"
//                         getConfig={() => getMLSyncConfig()}
//                         defaultConfig={() =>
//                             Promise.resolve(DEFAULT_ML_SYNC_CONFIG)
//                         }
//                         setConfig={(mlSyncConfig) =>
//                             updateMLSyncConfig(mlSyncConfig as MLSyncConfig)
//                         }></ConfigEditor>
//                 </Col>

//                 <Col>
//                     <ConfigEditor
//                         name="ML Sync Job"
//                         getConfig={() => getMLSyncJobConfig()}
//                         defaultConfig={() =>
//                             Promise.resolve(DEFAULT_ML_SYNC_JOB_CONFIG)
//                         }
//                         setConfig={(mlSyncJobConfig) =>
//                             updateMLSyncJobConfig(mlSyncJobConfig as JobConfig)
//                         }></ConfigEditor>
//                 </Col>
//             </Row>

//             {/* <div>MinFaceSize: {minFaceSize}</div>
//             <button onClick={() => setMinFaceSize(16)}>16</button>
//             <button onClick={() => setMinFaceSize(24)}>24</button>
//             <button onClick={() => setMinFaceSize(32)}>32</button>
//             <button onClick={() => setMinFaceSize(64)}>64</button>
//             <button onClick={() => setMinFaceSize(112)}>112</button>

//             <p></p>
//             <div>MinClusterSize: {minClusterSize}</div>
//             <button onClick={() => setMinClusterSize(2)}>2</button>
//             <button onClick={() => setMinClusterSize(3)}>3</button>
//             <button onClick={() => setMinClusterSize(4)}>4</button>
//             <button onClick={() => setMinClusterSize(5)}>5</button>
//             <button onClick={() => setMinClusterSize(8)}>8</button>
//             <button onClick={() => setMinClusterSize(12)}>12</button>

//             <p></p>
//             <div>Number of Images in Batch: {batchSize}</div>
//             <button onClick={() => setBatchSize(50)}>50</button>
//             <button onClick={() => setBatchSize(100)}>100</button>
//             <button onClick={() => setBatchSize(200)}>200</button>
//             <button onClick={() => setBatchSize(500)}>500</button> */}

//             {/* <p></p>
//             <div>MaxFaceDistance: {maxFaceDistance}</div>
//             <button onClick={() => setMaxFaceDistance(0.45)}>0.45</button>
//             <button onClick={() => setMaxFaceDistance(0.5)}>0.5</button>
//             <button onClick={() => setMaxFaceDistance(0.55)}>0.55</button>
//             <button onClick={() => setMaxFaceDistance(0.6)}>0.6</button> */}

//             <hr />
//             <RowWithGap>
//                 <Button onClick={onSync} disabled>
//                     Run ML Sync
//                 </Button>
//                 <Button onClick={onStartMLSync}>Start ML Sync</Button>
//                 <Button onClick={onStopMLSync}>Stop ML Sync</Button>
//             </RowWithGap>

//             <hr />
//             <RowWithGap>
//                 <Button onClick={onExportMLData}>Export ML Data</Button>
//                 <Button onClick={onImportMLData}>Import ML Data</Button>
//                 <Button onClick={onClearPeopleIndex}>Clear People Index</Button>
//             </RowWithGap>

//             <hr />
//             <RowWithGap>
//                 <Button onClick={onLoadAllPeople}>
//                     Load All Identified People
//                 </Button>
//             </RowWithGap>
//             <Row>All identified people:</Row>
//             <PeopleList people={allPeople}></PeopleList>

//             <hr />
//             <RowWithGap>
//                 <Button onClick={onLoadClusteringResults}>
//                     Load Clustering Results
//                 </Button>
//             </RowWithGap>

//             <Row>Clusters:</Row>
//             {clusters.map((cluster, index) => (
//                 <ClusterFacesRow key={index}>
//                     {cluster?.map((face, i) => (
//                         <ImageBlobView key={i} blob={face}></ImageBlobView>
//                     ))}
//                 </ClusterFacesRow>
//             ))}

//             <p></p>
//             <Row>Noise:</Row>
//             <ClusterFacesRow>
//                 {noiseFaces?.map((face, i) => (
//                     <ImageBlobView key={i} blob={face}></ImageBlobView>
//                 ))}
//             </ClusterFacesRow>

//             <hr />
//             <Row>Show Faces based on detection probability:</Row>
//             <Row style={{ alignItems: 'end' }}>
//                 <Col>
//                     <Form.Label htmlFor="minProbability">Min: </Form.Label>
//                     <Form.Control
//                         type="number"
//                         id="minProbability"
//                         placeholder="e.g. 70"
//                         onChange={(e) =>
//                             setMinProbability(
//                                 (parseFloat(e.target.value) || 0) / 100
//                             )
//                         }
//                     />
//                 </Col>
//                 <Col>
//                     <Form.Label htmlFor="maxProbability">Max: </Form.Label>
//                     <Form.Control
//                         type="number"
//                         id="maxProbability"
//                         placeholder="e.g. 80"
//                         onChange={(e) =>
//                             setMaxProbability(
//                                 (parseFloat(e.target.value) || 100) / 100
//                             )
//                         }
//                     />
//                 </Col>
//                 <Col>
//                     <Button onClick={showFilteredFaces}>Show Faces</Button>
//                 </Col>
//             </Row>
//             <p></p>
//             <ClusterFacesRow>
//                 {filteredFaces?.map((face, i) => (
//                     <ImageBlobView key={i} blob={face}></ImageBlobView>
//                 ))}
//             </ClusterFacesRow>

//             <hr />
//             <Row>Debug File:</Row>
//             <input id="debugFile" type="file" onChange={onDebugFile} />
//             <MLFileDebugView file={debugFile} />

//             <hr />
//             <Row>Hdbscan MST: </Row>
//             <div
//                 id="treeWrapper"
//                 style={{
//                     width: '100%',
//                     height: '50em',
//                     backgroundColor: 'white',
//                 }}>
//                 {mstD3Tree && (
//                     <Tree
//                         data={mstD3Tree}
//                         orientation={'vertical'}
//                         nodeSize={nodeSize}
//                         zoom={0.25}
//                         renderCustomNodeElement={(rd3tProps) =>
//                             renderForeignObjectNode({
//                                 ...rd3tProps,
//                                 foreignObjectProps,
//                             })
//                         }
//                     />
//                 )}
//             </div>

//             <hr />
//             <Row>TSNE of embeddings: </Row>
//             <Row>
//                 <div
//                     id="tsneWrapper"
//                     style={{
//                         width: '840px',
//                         height: '840px',
//                         backgroundColor: 'white',
//                         overflow: 'auto',
//                     }}>
//                     {mlResult.tsne && <TSNEPlot mlResult={mlResult} />}
//                 </div>
//             </Row>
//         </Container>
//     );
// }
