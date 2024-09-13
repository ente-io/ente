import { decryptMetadataJSON_New } from '@/base/crypto';
import React, { useState, useEffect } from 'react';

interface SharedCodes {
  startTime: number;
  step: number;
  codes: string;
}

const Share: React.FC = () => {
  const [decryptedData, setDecryptedData] = useState<SharedCodes | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [timeStatus, setTimeStatus] = useState(-10);
  const [currentCode, setCurrentCode] = useState('');
  const [nextCode, setNextCode] = useState('');
  const [progress, setProgress] = useState(0);

  const base64UrlToByteArray = (base64Url: string): Uint8Array => {
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const binaryString = atob(base64);
    const len = binaryString.length;
    const bytes = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes;
  };

  const getCurrentAndNextCode = (
    codes: string[],
    startTime: number,
    stepDuration: number
  ): { currentCode: string; nextCode: string } => {
    const currentTime = Date.now();
    const elapsedTime = Math.floor((currentTime - startTime) / 1000);
    const index = Math.floor(elapsedTime / stepDuration);
    const currentCode = codes[index] || '';
    const nextCode = codes[index + 1] || '';
    return { currentCode, nextCode };
  };

  const getTimeStatus = (
    currentTime: number,
    startTime: number,
    codes: string[],
    stepDuration: number
  ): number => {
    if (currentTime < startTime) return -1;
    const totalDuration = codes.length * stepDuration * 1000;
    if (currentTime > startTime + totalDuration) return 1;
    return 0;
  };

  useEffect(() => {
    const decryptData = async () => {
      const queryParams = new URLSearchParams(window.location.search);
      const dataParam = queryParams.get('data');
      const headerParam = queryParams.get('header');
      const keyParam = window.location.hash.substring(1);
      if (dataParam && headerParam && keyParam) {
        try {
          const decryptedCode: SharedCodes = await decryptMetadataJSON_New(
            {
              encryptedData: base64UrlToByteArray(dataParam),
              decryptionHeader: base64UrlToByteArray(headerParam),
            },
            base64UrlToByteArray(keyParam)
          ) as SharedCodes;
          setDecryptedData(decryptedCode);
        } catch (error) {
          console.error('Failed to decrypt data:', error);
          setError('Failed to get the data. Please check the URL and try again.');
        }
      }
    };
    decryptData();
  }, []);

  useEffect(() => {
    if (decryptedData) {
      const interval = setInterval(() => {
        const currentTime = Date.now();
        const timeStatus = getTimeStatus(
          currentTime,
          decryptedData.startTime,
          decryptedData.codes.split(','),
          decryptedData.step
        );
        setTimeStatus(timeStatus);
        if (timeStatus === 0) {
          const { currentCode, nextCode } = getCurrentAndNextCode(
            decryptedData.codes.split(','),
            decryptedData.startTime,
            decryptedData.step
          );
          setCurrentCode(currentCode);
          setNextCode(nextCode);

          const elapsedTime = (currentTime - decryptedData.startTime) / 1000;
          const progress = (elapsedTime % decryptedData.step) / decryptedData.step * 100;
          setProgress(progress);
        }
      }, 1000);

      return () => clearInterval(interval);
    }
  }, [decryptedData]);

  return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh', flexDirection: 'column', textAlign: 'center' }}>
      <h1>Ente.io</h1>
      <div>
        {error && <p>{error}</p>}
        {timeStatus === -10 && error === null && <p>Decrypting...</p>}
        {timeStatus === -1 && <p>Your or the person who shared the code has out of sync time.</p>}
        {timeStatus === 1 && (
          <p>
            The code has expired.
          </p>
        )}
        {timeStatus === 0 && (
          <div style={{ border: '0.01px solid #000000',
            backgroundColor: "rgba(40, 40, 40, 0.6)",
            borderRadius: "4px",
            overflow: "hidden", width: '300px', position: 'relative' }}>
            <div style={{ width: '100%', backgroundColor: '#e0e0e0', height: '4px', borderRadius: '5px', overflow: 'hidden' }}>
              <div
                style={{
                  width: `${progress}%`,
                  height: '100%',
                  backgroundColor: progress > 0.4 ? "green" : "orange",
                  transition: 'width 1s linear',
                }}
              />
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '15px', margin:'15px', position: 'relative' }}>
              <div style={{ alignSelf: 'center', fontSize: '24px', fontWeight: 'bold' }}>{currentCode}</div>
              <div style={{ position: 'absolute', right: 0, bottom: 0, textAlign: 'right', fontSize: '10px', opacity: 0.6 }}>
                <p style={{ margin: 0 }}>Next</p>
                <p style={{ margin: 0 }}>{nextCode}</p>
              </div>
            </div>
    
          </div>
        )}
      </div>
    </div>
  );
};

export default Share;