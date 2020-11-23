import React, { useEffect, useState } from 'react';
import { file, getPreview } from 'services/fileService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import styled from 'styled-components';

interface IProps {
    data: file,
    updateUrl: (url: string) => void,
    onClick: () => void,
}

const Cont = styled.div<{ disabled: boolean }>`
    background: #555 url(/image.svg) no-repeat center;
    margin: 0 4px;
    display: inline-block;
    width: 192px;
    height: 192px;
    overflow: hidden;
    cursor: ${props => props.disabled ? 'not-allowed' : 'pointer'};

    & > img {
        object-fit: cover;
        max-width: 100%;
        min-height: 100%;
    }
`;

export default function PreviewCard(props: IProps) {
    const [imgSrc, setImgSrc] = useState<string>();
    const { data, onClick, updateUrl } = props;

    useEffect(() => {
        if (data && !data.src) {
            const main = async () => {
                const token = getData(LS_KEYS.USER).token;
                const url = await getPreview(token, data);
                setImgSrc(url);
                data.src = url;
                updateUrl(url);
            }
            main();
        }
    }, [data]);

    const handleClick = () => {
        if (data.src || imgSrc) {
            onClick();
        }
    }

    return <Cont onClick={handleClick} disabled={!data?.src && !imgSrc}>
        <img src={data?.src || imgSrc} />
    </Cont>;
}
