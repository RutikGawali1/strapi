// src/index.js
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { FlagProvider } from '@unleash/proxy-client-react';
import unleashClient from './unleashClient';

unleashClient.start();

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <FlagProvider unleashClient={unleashClient}>
    <App />
  </FlagProvider>
);
