import React, { useEffect, useState } from 'react';
import { file, getPreview } from 'services/fileService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import styled from 'styled-components';
import PlayCircleOutline from 'components/PlayCircleOutline';

interface IProps {
    data: file,
    updateUrl: (url: string) => void,
    onClick: () => void,
}

const Cont = styled.div<{ disabled: boolean }>`
    background: #555 url(/image.svg) no-repeat center;
    display: block;
    width: fit-content;
    height: 192px;
    min-width: 100%;
    overflow: hidden;
    position: relative;
    cursor: ${props => props.disabled ? 'not-allowed' : 'pointer'};

    & > img {
        object-fit: cover;
        max-width: 100%;
        min-height: 100%;
    }

    & > svg {
        position: absolute;
        color: white;
        width: 50px;
        height: 50px;
        margin-left: 50%;
        margin-top: 50%;
        top: -25px;
        left: -25px;
        filter: drop-shadow( 3px 3px 2px rgba(0, 0, 0, .7));
    }
`;

export default function PreviewCard(props: IProps) {
    const [imgSrc, setImgSrc] = useState<string>();
    const { data, onClick, updateUrl } = props;

    useEffect(() => {
        if (data && !data.msrc) {
            const main = async () => {
                const token = getData(LS_KEYS.USER).token;
                const url = await getPreview(token, data);
                setImgSrc(url);
                data.msrc = url;
                updateUrl(url);
            }
            main();
        }
    }, [data]);

    const handleClick = () => {
        if (data.msrc || imgSrc) {
            onClick();
        }
    }

    return <Cont onClick={handleClick} disabled={!data?.msrc && !imgSrc}>
        <img src={data?.msrc || imgSrc} />
        {data?.metadata.fileType === 1 && <PlayCircleOutline />}
    </Cont>;
}
