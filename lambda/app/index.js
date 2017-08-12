import express from 'express';
const app = express();

app.get('/', (req, res) => {
  res.setHeader('X-API-Version', '1.0.0');
  res.status(200).json({ success: true });
});

app.get('/health-check', (req, res) => {
  res.setHeader('X-API-Version', '1.0.0');
  res.status(200).json({ healthCheck: true });
});

export default app;