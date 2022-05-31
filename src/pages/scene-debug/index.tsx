import React, { useEffect, useState } from 'react';
import sceneDetectionService from 'services/machineLearning/imageSceneService';

function SceneDebug() {
    const [selectedFiles, setSelectedFiles] = useState<File[]>(null);

    const changeHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
        setSelectedFiles([...event.target.files]);
    };

    const handleSubmission = async () => {
        for (const file of selectedFiles) {
            console.log(
                `scene detection for file ${file.name}`,
                await sceneDetectionService.detectScenes(
                    await createImageBitmap(file),
                    0.1
                )
            );
        }
        console.log('done with scene detection');
    };

    useEffect(() => {
        console.log('loaded', selectedFiles);
    }, [selectedFiles]);

    return (
        <div>
            <input
                type="file"
                name="file"
                multiple={true}
                onChange={changeHandler}
            />
            <div>
                <button onClick={handleSubmission}>Submit</button>
            </div>
            {selectedFiles?.map((file, index) => (
                <div key={index}>
                    <img src={URL.createObjectURL(file)} width={'400px'} />
                    File: {file.name}
                </div>
            ))}
        </div>
    );
}

export default SceneDebug;
