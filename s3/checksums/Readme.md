## Create a new s3 bucket

```md
aws s3 mb s3://checksums-examples-ab-2342
```

## Create a file that will we do a checksum on

```
echo "Hello mars" > myfile.txt
``` 

## Get a checksum of a file for md5
md5sum myfile.txt

## Upload our file to se
aws s3 cp myfile.txt s3://checksums-examples-ab-2342
aws s3api head-objcet --bucket chceksum-examples-ab-2342 -key myfile.txt

## Lets upload a file with a different kind of checksum
aws s3 put-object \
--bucket \
--key myfile.txt \ 
--checksum-algorithm="CRC32"\ 
--checksum-crc32 = ""
