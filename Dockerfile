# ref. https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/go-image.html
FROM golang:1.21 as build
WORKDIR /hello
# Copy dependencies list
COPY go.mod go.sum ./
# Build with optional lambda.norpc tag
COPY ./cmd/hello/main.go .
RUN GOOS=linux GOARCH=amd64 go build -tags lambda.norpc -o main main.go

# Copy artifacts to a clean image
# Select image
FROM gcr.io/distroless/static:latest
# FROM gcr.io/distroless/base:latest
# FROM public.ecr.aws/lambda/provided:al2

COPY --from=build /hello/main ./main
ENTRYPOINT [ "./main" ]