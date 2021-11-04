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

export default function MLDebug() {
    const [token, setToken] = useState<string>();
    const [mlResult, setMlResult] = useState<MLSyncResult>({
        allFaces: [],
        clusterResults: {
            clusters: [],
            noise: [],
        },
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
            const result = await mlWorker.sync(token);
            setMlResult(result);
        } catch (e) {
            console.error(e);
            throw e;
        } finally {
            MLWorker.worker.terminate();
        }
    };
    return (
        <div>
            <button onClick={onSync}>Run ML Sync</button>
            <p>{JSON.stringify(mlResult.clusterResults)}</p>
            <div>
                <p>Clusters: </p>
                {mlResult.clusterResults.clusters.map((cluster, index) => (
                    <div key={index} style={{ display: 'flex' }}>
                        {cluster.map((faceIndex, ind) => (
                            <div key={ind}>
                                <TFJSImage
                                    faceImage={
                                        mlResult.allFaces[faceIndex]?.faceImage
                                    }></TFJSImage>
                            </div>
                        ))}
                    </div>
                ))}

                <p style={{ marginTop: '1em' }}>Noise: </p>
                <div style={{ display: 'flex' }}>
                    {mlResult.clusterResults.noise.map((faceIndex, index) => (
                        <div key={index}>
                            <TFJSImage
                                faceImage={
                                    mlResult.allFaces[faceIndex]?.faceImage
                                }></TFJSImage>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
}
