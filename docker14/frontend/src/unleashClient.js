// src/unleashClient.js
import { UnleashClient } from '@unleash/proxy-client-react';

const unleashClient = new UnleashClient({
  url: process.env.REACT_APP_UNLEASH_URL,
  clientKey: process.env.REACT_APP_UNLEASH_CLIENT_KEY,
  appName: process.env.REACT_APP_UNLEASH_APP_NAME,
});

export default unleashClient;
