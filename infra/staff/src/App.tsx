import React, { useState } from "react";

import S from "./utils/strings";

export const App: React.FC = () => {
  const [serverUrl, setServerUrl] = useState("");
  const [token, setToken] = useState("");
  const [userId, setUserId] = useState("");
  const [userData, setUserData] = useState(null);
  const [error, setError] = useState<string | null>(null);

  const fetchData = async () => {
    try {
      const url = `${serverUrl}/admin/user?id=${userId}&token=${token}`;
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
      const userData = await response.json();
      console.log("API Response:", userData);
      setUserData(userData);
      setError(null);
    } catch (error) {
      console.error("Error fetching data:", error);
      setError((error as Error).message);
    }
  };

  const renderAttributes = (data: any) => {
    if (!data) return null;
  
    let nullAttributes: string[] = [];
  
    const rows = Object.entries(data).map(([key, value]) => {
      console.log("Processing key:", key, "value:", value);
  
      if (typeof value === "object" && value !== null && !Array.isArray(value)) {
        return (
          <React.Fragment key={key}>
            <tr>
              <td colSpan={2} style={{ fontWeight: 'bold', backgroundColor: '#f1f1f1', padding: '10px' }}>{key.toUpperCase()}</td>
            </tr>
            {renderAttributes(value)}
          </React.Fragment>
        );
      } else {
        if (value === null) {
          nullAttributes.push(key);
        }
  
        // Special handling for expiryTime key
        let displayValue = value;
        if (key === "expiryTime" && typeof value === "number") {
          displayValue = new Date(value / 1000).toLocaleString();
        } 
       else if (key === "creationTime" && typeof value === "number") {
            displayValue = new Date(value / 1000).toLocaleString();
          } 
        
        
        else if (key === "storage") {
          displayValue = value === null ? "null" : `${(value / (1024 ** 3)).toFixed(2)} GB`;
        } else {
          displayValue = value === null ? "null" : JSON.stringify(value);
        }
  
        return (
          <tr key={key}>
            <td style={{ padding: '10px', border: '1px solid #ddd' }}>{key}</td>
            <td style={{ padding: '10px', border: '1px solid #ddd' }}>{displayValue}</td>
          </tr>
        );
      }
    });
  
    console.log("Attributes with null values:", nullAttributes);
  
    return rows;
  };
  

  return (
    <div className="container center-table">
      <h1>{S.hello}</h1>
     
      <form className="input-form">
        <div className="input-group">
          <label>
            Server URL:
            <input
              type="text"
              value={serverUrl}
              onChange={(e) => setServerUrl(e.target.value)}
              style={{ padding: '10px', margin: '10px', width: '100%' }}
            />
          </label>
        </div>
        <div className="input-group">
          <label>
            Token:
            <input
              type="text"
              value={token}
              onChange={(e) => setToken(e.target.value)}
              style={{ padding: '10px', margin: '10px', width: '100%' }}
            />
          </label>
        </div>
        <div className="input-group">
          <label>
            User ID:
            <input
              type="text"
              value={userId}
              onChange={(e) => setUserId(e.target.value)}
              style={{ padding: '10px', margin: '10px', width: '100%' }}
            />
          </label>
        </div>
      </form>
      <div className="fetch-button">
        <button
          onClick={fetchData}
          style={{ padding: '10px 20px', fontSize: '16px', cursor: 'pointer', backgroundColor: '#009879', color: 'white', border: 'none', borderRadius: '5px' }}
        >
          FETCH
        </button>
      </div>
      <br />
      {error && <p style={{ color: 'red' }}>{`Error: ${error}`}</p>}
      {userData && (
        <table style={{ width: '100%', borderCollapse: 'collapse', margin: '20px 0', fontSize: '1em', minWidth: '400px', boxShadow: '0 0 20px rgba(0, 0, 0, 0.15)' }}>
          <tbody>
            {Object.keys(userData).map((category) => (
              <React.Fragment key={category}>
                <tr>
                  <td colSpan={2} style={{ fontWeight: 'bold', backgroundColor: '#f1f1f1', padding: '10px' }}>{category.toUpperCase()}</td>
                </tr>
                {renderAttributes(userData[category])}
              </React.Fragment>
            ))}
          </tbody>
        </table>
      )}
      <footer className="footer">
      <p>
        <a href="https://help.ente.io">help.ente.io</a>
      </p>
      </footer>
    </div>
  );
};
