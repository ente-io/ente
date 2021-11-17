import React, { useState, useEffect, useContext } from 'react';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { ComlinkWorker } from 'utils/crypto';
import { AppContext } from 'pages/_app';
import { PAGES } from 'types';
import * as Comlink from 'comlink';
import { runningInBrowser } from 'utils/common';
import { MLSyncResult } from 'utils/machineLearning/types';
import TFJSImage from './TFJSImage';
import Tree from 'react-d3-tree';

interface TSNEProps {
    mlResult: MLSyncResult;
}

function TSNEPlot(props: TSNEProps) {
    return (
        <svg
            width={props.mlResult.tsne.width + 40}
            height={props.mlResult.tsne.height + 40}>
            {props.mlResult.tsne.dataset.map((data, i) => (
                <foreignObject
                    key={i}
                    x={data.x - 20}
                    y={data.y - 20}
                    width={40}
                    height={40}>
                    <TFJSImage
                        faceImage={props.mlResult.allFaces[i]?.faceImage}
                        width={40}
                        height={40}></TFJSImage>
                </foreignObject>
            ))}
        </svg>
    );
}

const renderForeignObjectNode = ({
    nodeDatum,
    foreignObjectProps,
    mlResult,
}) => (
    <g>
        <circle r={15}></circle>
        {/* `foreignObject` requires width & height to be explicitly set. */}
        <foreignObject {...foreignObjectProps}>
            <div
                style={{
                    border: '1px solid black',
                    backgroundColor: '#dedede',
                }}>
                <h3 style={{ textAlign: 'center', color: 'black' }}>
                    {nodeDatum.name}
                </h3>
                {!nodeDatum.children && nodeDatum.name && (
                    <TFJSImage
                        faceImage={
                            mlResult.allFaces[nodeDatum.name]?.faceImage
                        }></TFJSImage>
                )}
            </div>
        </foreignObject>
    </g>
);

export default function MLDebug() {
    const [token, setToken] = useState<string>();
    const [clusterFaceDistance, setClusterFaceDistance] = useState<number>(0.4);
    const [minClusterSize, setMinClusterSize] = useState<number>(5);
    const [minFaceSize, setMinFaceSize] = useState<number>(32);
    const [batchSize, setBatchSize] = useState<number>(200);
    const [maxFaceDistance, setMaxFaceDistance] = useState<number>(0.5);
    const [mlResult, setMlResult] = useState<MLSyncResult>({
        allFaces: [],
        clustersWithNoise: {
            clusters: [],
            noise: [],
        },
        tree: null,
        tsne: null,
    });
    const router = useRouter();
    const appContext = useContext(AppContext);

    const getDedicatedMLWorker = (): ComlinkWorker => {
        if (token) {
            console.log('Toen present');
        }
        if (runningInBrowser()) {
            console.log('initiating worker');
            const worker = new Worker(
                new URL('worker/machineLearning.worker.js', import.meta.url),
                { name: 'ml-worker' }
            );
            console.log('initiated worker');
            const comlink = Comlink.wrap(worker);
            return { comlink, worker };
        }
    };
    let MLWorker: ComlinkWorker;

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (!user?.token) {
            router.push(PAGES.ROOT);
        } else {
            setToken(user.token);
        }
        appContext.showNavBar(true);
    }, []);

    const onSync = async () => {
        try {
            if (!MLWorker) {
                MLWorker = getDedicatedMLWorker();
                console.log('initiated MLWorker');
            }
            const mlWorker = await new MLWorker.comlink();
            const result = await mlWorker.sync(
                token,
                clusterFaceDistance,
                minClusterSize,
                minFaceSize,
                batchSize,
                maxFaceDistance
            );
            setMlResult(result);
        } catch (e) {
            console.error(e);
            throw e;
        } finally {
            // setTimeout(()=>{
            //     console.log('terminating ml-worker');
            MLWorker.worker.terminate();
            // }, 30000);
        }
    };

    const nodeSize = { x: 180, y: 180 };
    const foreignObjectProps = { width: 112, height: 150, x: -56 };

    return (
        <div>
            <div>ClusterFaceDistance: {clusterFaceDistance}</div>
            <button onClick={() => setClusterFaceDistance(0.35)}>0.35</button>
            <button onClick={() => setClusterFaceDistance(0.4)}>0.4</button>
            <button onClick={() => setClusterFaceDistance(0.45)}>0.45</button>
            <button onClick={() => setClusterFaceDistance(0.5)}>0.5</button>
            <button onClick={() => setClusterFaceDistance(0.55)}>0.55</button>
            <button onClick={() => setClusterFaceDistance(0.6)}>0.6</button>

            <p></p>
            <div>MinFaceSize: {minFaceSize}</div>
            <button onClick={() => setMinFaceSize(16)}>16</button>
            <button onClick={() => setMinFaceSize(24)}>24</button>
            <button onClick={() => setMinFaceSize(32)}>32</button>
            <button onClick={() => setMinFaceSize(64)}>64</button>
            <button onClick={() => setMinFaceSize(112)}>112</button>

            <p></p>
            <div>MinClusterSize: {minClusterSize}</div>
            <button onClick={() => setMinClusterSize(2)}>2</button>
            <button onClick={() => setMinClusterSize(3)}>3</button>
            <button onClick={() => setMinClusterSize(4)}>4</button>
            <button onClick={() => setMinClusterSize(5)}>5</button>
            <button onClick={() => setMinClusterSize(8)}>8</button>
            <button onClick={() => setMinClusterSize(12)}>12</button>

            <p></p>
            <div>Number of Images in Batch: {batchSize}</div>
            <button onClick={() => setBatchSize(50)}>50</button>
            <button onClick={() => setBatchSize(100)}>100</button>
            <button onClick={() => setBatchSize(200)}>200</button>
            <button onClick={() => setBatchSize(500)}>500</button>

            <p></p>
            <div>MaxFaceDistance: {maxFaceDistance}</div>
            <button onClick={() => setMaxFaceDistance(0.45)}>0.45</button>
            <button onClick={() => setMaxFaceDistance(0.5)}>0.5</button>
            <button onClick={() => setMaxFaceDistance(0.55)}>0.55</button>
            <button onClick={() => setMaxFaceDistance(0.6)}>0.6</button>

            <p></p>
            <button onClick={onSync}>Run ML Sync</button>

            <p>{JSON.stringify(mlResult.clustersWithNoise)}</p>
            <div>
                <p>Clusters: </p>
                {mlResult.clustersWithNoise.clusters.map((cluster, index) => (
                    <div key={index} style={{ display: 'flex' }}>
                        {cluster.faces.map((faceIndex, ind) => (
                            <div key={ind}>
                                <TFJSImage
                                    faceImage={
                                        mlResult.allFaces[faceIndex].faceImage
                                    }></TFJSImage>
                            </div>
                        ))}
                    </div>
                ))}

                <p style={{ marginTop: '1em' }}>Noise: </p>
                <div style={{ display: 'flex' }}>
                    {mlResult.clustersWithNoise.noise.map(
                        (faceIndex, index) => (
                            <div key={index}>
                                <TFJSImage
                                    faceImage={
                                        mlResult.allFaces[faceIndex].faceImage
                                    }></TFJSImage>
                            </div>
                        )
                    )}
                </div>
            </div>

            <p></p>
            <div
                id="treeWrapper"
                style={{
                    width: '100%',
                    height: '50em',
                    backgroundColor: 'white',
                }}>
                {mlResult.tree && (
                    <Tree
                        data={mlResult.tree}
                        orientation={'vertical'}
                        nodeSize={nodeSize}
                        zoom={0.25}
                        renderCustomNodeElement={(rd3tProps) =>
                            renderForeignObjectNode({
                                ...rd3tProps,
                                foreignObjectProps,
                                mlResult,
                            })
                        }
                    />
                )}
            </div>
            <p></p>
            <div
                id="tsneWrapper"
                style={{
                    width: '840px',
                    height: '840px',
                    backgroundColor: 'white',
                }}>
                {mlResult.tsne && <TSNEPlot mlResult={mlResult} />}
            </div>
        </div>
    );
}
