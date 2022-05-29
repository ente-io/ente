import React, { useEffect, useState } from 'react';
import sceneDetectionService from 'services/machineLearning/sceneDetectionService';

function SceneDebug() {
    const [selectedFile, setSelectedFile] = useState<File>(null);

    const changeHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
        setSelectedFile(event.target.files[0]);
    };

    const handleSubmission = async () => {
        const model = await sceneDetectionService.init();
        await sceneDetectionService.run(selectedFile, model);
    };

    useEffect(() => {
        console.log(selectedFile);
    }, [selectedFile]);

    return (
        <div>
            <input type="file" name="file" onChange={changeHandler} />
            <div>
                <button onClick={handleSubmission}>Submit</button>
            </div>
            {selectedFile && (
                <img src={URL.createObjectURL(selectedFile)} width={'400px'} />
            )}
        </div>
    );
}

export default SceneDebug;
