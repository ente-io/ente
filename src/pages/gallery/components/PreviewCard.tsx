import React, { useEffect, useState } from 'react';
import { fileData, getPreview } from 'services/fileService';
import { getActualKey } from 'utils/common/key';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import styled from 'styled-components';

interface IProps {
    data: fileData,
}

const Cont = styled.div`
    background: #555 url(/image.svg) no-repeat center;
    margin: 0 4px;
    display: inline-block;
    width: 200px;
    height: 200px;
    overflow: hidden;

    & > img {
        object-fit: cover;
        max-width: 100%;
        min-height: 100%;
    }
`;

export default function PreviewCard(props: IProps) {
    const [imgSrc, setImgSrc] = useState<string>();
    const { data } = props;

    useEffect(() => {
        if (data) {
            const main = async () => {
                const token = getData(LS_KEYS.USER).token;
                const key = await getActualKey();
                const url = await getPreview(token, data, key);
                setImgSrc(url);
                data.src = url;
            }
            main();
        }
    }, [data]);

    return <Cont>
        <img src={imgSrc}/>
    </Cont>;
}
