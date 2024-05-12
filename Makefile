AWS_PROFILE_NAME=your-profile-name
AWS_REGION=ap-northeast-1
AWS_ACCOUNT_ID=your-account-id
AWS_ECR_REPO=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
AWS_LAMBDA_FUNC_NAME=hello-func
AWS_LAMBDA_FUNC_NAME_ZIP=hello-func-zip

DOCKER_IMAGE_NAME=hello
DOCKER_BUILD_PLATFORM=linux/arm64

go/build:
	GOOS=linux GOARCH=amd64 go build -tags lambda.norpc -o ./terraform/aws/bootstrap ./cmd/main.go
	zip -j ./terraform/aws/bootstrap.zip ./terraform/aws/bootstrap

docker/image/build:
	docker build --platform ${DOCKER_BUILD_PLATFORM} -t ${AWS_ECR_REPO}/${DOCKER_IMAGE_NAME} .

# after run, the following commands can be used to check.
#
# curl "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'
# or
# curl "http://localhost:9000/2015-03-31/functions/function/invocations" -v -d '{"payload":"hello world!"}'
docker/run:
	docker run -d -p 9000:8080 \
		--entrypoint /usr/local/bin/aws-lambda-rie \
		${AWS_ECR_REPO}/${DOCKER_IMAGE_NAME} ./main

docker/push: docker/image/build aws/ecr/login 
	docker push ${AWS_ECR_REPO}/${DOCKER_IMAGE_NAME}

aws/profle/check:
	 if [ `aws configure list | grep "profile                  ${AWS_PROFILE_NAME}" | wc -l` -eq 0 ]; then >&2 echo "ERROR: profile is not ${AWS_PROFILE_NAME}"; exit 1; fi

aws/ecr/login: aws/profle/check
	aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

aws/lambda/func/update/container: aws/profle/check
	aws lambda update-function-code --function-name ${AWS_LAMBDA_FUNC_NAME} --publish --image-uri ${AWS_ECR_REPO}/${DOCKER_IMAGE_NAME}:latest | jq -r '.Version'
	aws lambda update-alias --function-name ${AWS_LAMBDA_FUNC_NAME} --name current --function-version `aws lambda list-versions-by-function --function-name ${AWS_LAMBDA_FUNC_NAME} | jq -r '.Versions[-1].Version'` | jq -r

aws/lambda/func/update/zip: go/build aws/profle/check
	aws lambda update-function-code --function-name ${AWS_LAMBDA_FUNC_NAME_ZIP} --publish --zip-file fileb://./terraform/aws/bootstrap.zip | jq -r
	aws lambda update-alias --function-name ${AWS_LAMBDA_FUNC_NAME_ZIP} --name current --function-version `aws lambda list-versions-by-function --function-name ${AWS_LAMBDA_FUNC_NAME_ZIP} | jq -r '.Versions[-1].Version'` | jq -r

terraform/plan: aws/profle/check
	terraform-v1.6.1 -chdir=./terraform/aws plan

terraform/apply: aws/profle/check
	terraform-v1.6.1 -chdir=./terraform/aws apply

terraform/destroy: aws/profle/check
	terraform-v1.6.1 -chdir=./terraform/aws destroy