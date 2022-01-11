import React, { useEffect, useState } from 'react';
import { Row, Col, Button } from 'react-bootstrap';
import Editor from 'react-simple-code-editor';
import { Config } from 'types/common/config';

export function ConfigEditor(props: {
    name: string;
    getConfig: () => Promise<Config>;
    defaultConfig: () => Promise<Config>;
    setConfig: (config: Config) => Promise<string>;
}) {
    const [configStr, setConfigStr] = useState('');

    useEffect(() => {
        loadConfig();
    }, []);

    const loadConfig = async () => {
        const config = await props.getConfig();
        setConfigStr(JSON.stringify(config, null, '\t'));
    };

    const loadDefaultConfig = async () => {
        const config = await props.defaultConfig();
        setConfigStr(JSON.stringify(config, null, '\t'));
    };

    const updateConfig = async () => {
        const configObj = JSON.parse(configStr);
        props.setConfig(configObj);
    };

    return (
        <>
            <Row>{props.name} Config:</Row>
            <Row
                style={{
                    height: '200px',
                    overflow: 'auto',
                    marginTop: '15px',
                    marginBottom: '15px',
                }}>
                <Col>
                    <Editor
                        value={configStr}
                        onValueChange={(config) => setConfigStr(config)}
                        highlight={(code) => code}
                        padding={10}
                        style={{
                            background: 'white',
                        }}
                    />
                </Col>
            </Row>
            <Row>
                <Col>
                    <Button onClick={() => loadConfig()}>Reload</Button>
                </Col>
                <Col>
                    <Button onClick={() => loadDefaultConfig()}>
                        Defaults
                    </Button>
                </Col>
                <Col>
                    <Button onClick={() => updateConfig()}>Update</Button>
                </Col>
            </Row>
        </>
    );
}
