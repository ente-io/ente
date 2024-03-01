import { FILE_TYPE } from "constants/file";
import PhotoAuditorium from "./PhotoAuditorium";
// import VideoAuditorium from './VideoAuditorium';

interface fileProp {
    fileName: string;
    fileURL: string;
    type: FILE_TYPE;
}

interface IProps {
    file1: fileProp;
    file2: fileProp;
}

export default function Theatre(props: IProps) {
    switch (props.file1.type && props.file2.type) {
        case FILE_TYPE.IMAGE:
            return (
                <PhotoAuditorium
                    url={props.file1.fileURL}
                    nextSlideUrl={props.file2.fileURL}
                />
            );
        // case FILE_TYPE.VIDEO:
        //     return (
        //         <VideoAuditorium name={props.fileName} url={props.fileURL} />
        //     );
    }
}
