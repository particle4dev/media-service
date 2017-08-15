# Media service

### Setup infrastructure

```
  ./bin/setup init
  ./bin/setup plan
```

### URL

```
http://[BucketWebsiteHost]/c300x300/image.png // crop
http://[BucketWebsiteHost]/r300x300/image.png // resize
```

### Command line

```
sms setup - Setup key and infrastructure 
sms build - Build lambda source code (npm install)
sns deploy - Deploy lambda function to aws
sns generate - 
sns test - run test
sns dev - 
```
