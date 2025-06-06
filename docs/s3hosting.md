# How to serve Heartwood from S3
## 1. Create an S3 bucket
1. Create a new S3 bucket that is the name of your domain (e.g. `example.com`).
2. Set permissions in the Bucket Policy to allow public access.
    ```json
        {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "BucketPolicy",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::{{ACCOUNT_ID}}:root"
            },
            "Action": [
                "s3:GetBucketAcl",
                "s3:GetBucketCORS",
                "s3:PutBucketPolicy",
                "s3:ListBucket",
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:PutObjectACL",
                "s3:GetBucketPolicy",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::{{BUCKET}}",
                "arn:aws:s3:::{{BUCKET}}/*"
            ]
        },
        {
            "Sid": "PublicRead",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::{{BUCKET}}/*"
        }
    ]
    }
    ```

3. Set the bucket to be a static website.
    1. Under Properties, enable "Static website hosting".
    2. Set the index document to `index.html`.
4. Update your blueprint.yml to copy files to the bucket when bundling Heartwood.

    ```yaml
    theatre:
        - POST_BUNDLE_SCRIPT: |
                AWS_ACCESS_KEY_ID={{KEY}} AWS_REGION=us-east-1 AWS_SECRET_ACCESS_KEY={{SECRET}} \
                aws s3 sync \
                    ./packages/spruce-heartwood-skill/dist/ s3://{{BUCKET_NAME}}/  \
                    --cache-control "max-age=1,public" \
                    --metadata-directive REPLACE \
                    --delete
    ```
## 2. Setup SSL with ACM Console (once for Heratwood, once for Mercury)
1. Go to the AWS Certificate Manager (ACM) console.
2. Request a public certificate for your domain (e.g. `example.com`).
3. Add the domain name and any subdomains you want to cover (e.g. `www.example.com`).
4. Validate the certificate using DNS validation.
    1. ACM will provide a CNAME record to add to your DNS provider.
    2. Add the CNAME record to your DNS provider and wait for validation.
5. Once validated, the certificate will be issued and available in ACM.

## 3. Setup CloudFront for Heartwood
1. Go to the CloudFront console.
2. Create a new CloudFront distribution.
3. Set the origin to your S3 bucket (e.g. `example.com.s3.amazonaws.com`).
    1. Do not use s3-website endpoint, use the S3 bucket endpoint instead.
4. Set the default root object to `index.html`.
5. Under "Viewer Protocol Policy", select "Redirect HTTP to HTTPS".
6. Under "SSL Certificate", select "Custom SSL Certificate" and choose the certificate you created in ACM.
7. Under Alternative Domain Names (CNAMEs), add your domain name (e.g. `example.com` and `www.example.com`).
7. Do not enable Web Application Firewall (WAF), as it is not needed.
8. Setup your CNAME in your DNS provider to point to the CloudFront distribution domain name (e.g. `d1234567890abcdef.cloudfront.net`).

## 4. Setup CloudFront for Mercury
1. Go to the CloudFront console.
2. Create a new CloudFront distribution.
3. Set the origin the public DNS of the EC2 instance running Mercury, eg. ec2-107-23-116-102.compute-1.amazonaws.com.
4. Under "Viewer Protocol Policy", select "Redirect HTTP to HTTPS".
5. Under "SSL Certificate", select "Custom SSL Certificate" and choose the certificate you created in ACM.
5. Under Alternative Domain Names (CNAMEs), add your domain name (e.g. `mercury.example.com`).
7. Do not enable Web Application Firewall (WAF), as it is not needed.
8. Setup your CNAME in your DNS provider to point to the CloudFront distribution domain name (e.g. `d1234567890abcdef.cloudfront.net`).

## 5. Cors and Cache policies
This was a mess, run through again and document next time.
