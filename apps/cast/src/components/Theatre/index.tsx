import { FILE_TYPE } from 'constants/file';
import PhotoAuditorium from './PhotoAuditorium';
import VideoAuditorium from './VideoAuditorium';

interface IProps {
    fileName: string;
    fileURL: string;
    type: FILE_TYPE;
}

export default function Theatre(props: IProps) {
    switch (props.type) {
        case FILE_TYPE.IMAGE:
            return <PhotoAuditorium url={props.fileURL} />;
        case FILE_TYPE.VIDEO:
            return (
                <VideoAuditorium name={props.fileName} url={props.fileURL} />
            );
    }
}
