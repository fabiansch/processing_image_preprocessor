## setup
```
docker build -t image_processor .
```
```
docker run -p 3000:3000 -v $(pwd)/app:/app image_processor
```

## API

post /process_image
input: ``{'base64': [MIMETYPE;base64,]IMAGE_BASE64_DATA_STRING, 'frame_rate': int}``
output: ``{'base64': 'IMAGE_PNG_BASE64_STRING"}``

