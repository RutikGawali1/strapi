// src/App.js
import React from 'react';
import { useFlag } from '@unleash/proxy-client-react';

function App() {
  const showSecret = useFlag('secret-message');

  return (
    <div>
      <h1>Hello from React + Unleash</h1>
      {showSecret ? <p>🎉 This is a secret message!</p> : <p>🔒 Feature is disabled</p>}
    </div>
  );
}

export default App;
