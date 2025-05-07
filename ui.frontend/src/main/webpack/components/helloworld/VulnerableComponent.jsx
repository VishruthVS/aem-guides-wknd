import React, { useState, useEffect } from 'react';

// Hardcoded credentials (security issue)
const API_KEY = "sk_test_51L8J7gHK6sQRgVTYoplm1234567890abcdefghijklmn";
const SECRET_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ";
const PASSWORD = "admin123Password!";

/**
 * A component with various security vulnerabilities for CodeQL to detect
 */
const VulnerableComponent = ({ userId, role }) => {
  const [data, setData] = useState(null);
  const [userInput, setUserInput] = useState('');
  const [htmlContent, setHtmlContent] = useState('');
  const [loading, setLoading] = useState(false);
  
  // Insecure direct use of user input in URL (security issue)
  useEffect(() => {
    if (userId) {
      // URL injection vulnerability - userId is directly used without sanitization
      fetch(`https://api.example.com/users/${userId}/profile`)
        .then(response => response.json())
        .then(data => setData(data))
        .catch(error => console.error("Error fetching data:", error));
    }
  }, [userId]);

  // Insecure XSS vulnerability (security issue)
  const handleUserInput = (input) => {
    setUserInput(input);
    
    // Dangerous: directly setting HTML from user input - XSS vulnerability
    setHtmlContent(`<div>${input}</div>`);
    
    // Store data in localStorage without encryption
    localStorage.setItem('userInput', input);
  };

  // Insecure direct use of eval with user input (critical security issue)
  const calculateUserExpression = () => {
    try {
      // CRITICAL SECURITY ISSUE: Never use eval with user input!
      return eval(userInput);
    } catch (e) {
      return "Error in expression";
    }
  };

  // Regex Denial of Service (ReDoS) vulnerability
  const isValidEmail = (email) => {
    // Vulnerable regex pattern that can cause catastrophic backtracking
    const emailRegex = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
    return emailRegex.test(email);
  };

  // Insecure HTTP request without CSRF protection (security issue)
  const saveUserData = () => {
    setLoading(true);
    
    // Missing CSRF token in the request
    fetch('https://api.example.com/save', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        userId: userId,
        data: userInput,
        role: role
      })
    })
    .then(response => response.json())
    .then(result => {
      console.log('Success:', result);
      setLoading(false);
    })
    .catch(error => {
      console.error('Error:', error);
      setLoading(false);
    });
  };

  // SQL Injection vulnerability
  const getUserByUsername = (username) => {
    // SECURITY ISSUE: SQL injection vulnerability
    const query = `SELECT * FROM users WHERE username = '${username}'`;
    executeSQLQuery(query); // Assume this function exists
  };

  // Prototype pollution vulnerability
  const mergeObjects = (target, source) => {
    for (const key in source) {
      if (typeof source[key] === 'object') {
        target[key] = target[key] || {};
        // Recursive merge without proper checking can lead to prototype pollution
        mergeObjects(target[key], source[key]);
      } else {
        target[key] = source[key];
      }
    }
    return target;
  };

  // Insecure use of setTimeout with string argument
  const executeDelayedCode = (code) => {
    // SECURITY ISSUE: Using string in setTimeout is similar to eval
    setTimeout(code, 1000);
  };

  return (
    <div className="vulnerable-component">
      <h2>User Profile</h2>
      
      {data && (
        <div>
          <p>Name: {data.name}</p>
          <p>Email: {data.email}</p>
        </div>
      )}
      
      <div className="input-section">
        <input 
          type="text"
          value={userInput}
          onChange={(e) => handleUserInput(e.target.value)}
          placeholder="Enter some text or an expression"
        />
        
        {/* Insecure: Directly rendering HTML from state that contains user input */}
        <div dangerouslySetInnerHTML={{ __html: htmlContent }} />
        
        <button onClick={calculateUserExpression}>Calculate Expression</button>
        <button onClick={saveUserData} disabled={loading}>
          {loading ? 'Saving...' : 'Save Data'}
        </button>
      </div>
      
      {/* Hardcoded password in attribute (security issue) */}
      <iframe src={`https://example.com/frame?auth=${PASSWORD}`}></iframe>
      
      {/* More vulnerable code could be added here */}
    </div>
  );
};

// Function to execute a SQL query (mock implementation)
function executeSQLQuery(query) {
  console.log('Executing query:', query);
  // This would actually connect to a database in a real application
  return [];
}

// Dangerous export - exposing credentials
export { VulnerableComponent, API_KEY, SECRET_TOKEN };

export default VulnerableComponent;