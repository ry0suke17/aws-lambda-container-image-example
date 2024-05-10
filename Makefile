AWS_PROFILE_NAME=your-profile-name
AWS_REGION=ap-northeast-1
AWS_ACCOUNT_ID=your-account-id
AWS_ECR_REPO=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

DOCKER_IMAGE_NAME=hello
DOCKER_BUILD_PLATFORM=linux/arm64

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

docker/push: aws/ecr/login 
	docker push ${AWS_ECR_REPO}/${DOCKER_IMAGE_NAME}

aws/profle/check:
	 if [ `aws configure list | grep profile | grep ${AWS_PROFILE_NAME} | wc -l` -eq 0 ]; then >&2 echo "ERROR: profile is not ${AWS_PROFILE_NAME}"; exit 1; fi

aws/ecr/login: aws/profle/check
	aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

terraform/plan: aws/profle/check
	terraform-v1.6.1 -chdir=./terraform/aws plan

terraform/apply: aws/profle/check
	terraform-v1.6.1 -chdir=./terraform/aws apply

terraform/destroy: aws/profle/check
	terraform-v1.6.1 -chdir=./terraform/aws destroy