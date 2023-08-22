# DynamoDB Image Buildkite Plugin

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) that introspects the schema of DynamoDB tables and then publishes multi-arch (linux/arm64 and linux/amd64) [amazon/dynamodb-local](https://hub.docker.com/r/amazon/dynamodb-local) images with these schemas to [ECR](https://aws.amazon.com/ecr/).

For this plugin to work, you must ensure the following:

- The AWS credentials to access your table are available [in the environment](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)
- Docker is logged into ECR (e.g., by using [ecr-buildkite-plugin](https://github.com/buildkite-plugins/ecr-buildkite-plugin/))

## Example

TODO: Add examples once there is a release

## Configuration

- `repository` (required, string)

  The URI of the ECR repository to publish the image to.

- `tables` (required, string[])

  The names of the DynamoDB tables.

## License

MIT (see [LICENSE](LICENSE))
