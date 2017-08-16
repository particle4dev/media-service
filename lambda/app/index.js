import express from 'express';
import AWS from 'aws-sdk';
const app = express();

const S3 = new AWS.S3({
  signatureVersion: 'v4',
});

app.get('/', (req, res) => {

  S3.getObject({Bucket: 'media.particle4dev.com', Key: 'origin/logo.png'}).promise()
  .then((data) => {
    /**
    {
    AcceptRanges: 'bytes',
    LastModified: 2017-08-15T03:56:18.000Z,
    ContentLength: 6004,
    ETag: '"e478a7a1878eb87ea93a8888a2d57d06"',
    ContentType: 'binary/octet-stream',
    Metadata: {},
    Body: <Buffer 89 50 4e 47 0d 0a 1a 0a 00 00 00 0d 49 48 44 52 00 00 02 00 00 00 02 00 08 06 00 00 00 f4 78 d4 fa 00 00 17 3b 49 44 41 54 78 da ed dd 3f 6e e4 ca 9d ... >
    }
    */

    // console.log('data')
    // console.log(data)
    res.setHeader('X-API-Version', '1.0.0');
    // res.setHeader('Content-Type', data.ContentType);
    res.setHeader('Content-Type', "image/png");
    res.setHeader('Content-Length', data.ContentLength);
    // res.status(200).json({ success: true });
    // res.isBase64Encoded = true;

    res.end(data.Body);
    // res.status(200).end(data.Body.toString('base64'));
    // res.end(data.Body.toString('base64'), 'binary');
  })
  .catch((reason) => {
    console.log(reason);
    res.setHeader('X-API-Version', '1.0.0');
    res.status(200).json({ success: true });
  });
});

app.get('/health-check', (req, res) => {
  res.setHeader('X-API-Version', '1.0.0');
  res.status(200).json({ healthCheck: true });
});

export default app;
