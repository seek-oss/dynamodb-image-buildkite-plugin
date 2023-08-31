# DynamoDB Image Buildkite Plugin

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) that introspects the schema of DynamoDB tables and then publishes multi-arch (linux/arm64 and linux/amd64) [amazon/dynamodb-local](https://hub.docker.com/r/amazon/dynamodb-local) images with these schemas to [ECR](https://aws.amazon.com/ecr/).

## Usage Requirements

For this plugin to work, you must ensure the following:

- The AWS credentials to access your table are available [in the environment](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)
- Docker is logged into ECR (e.g., by using [ecr-buildkite-plugin](https://github.com/buildkite-plugins/ecr-buildkite-plugin/))

## Example

This will create an [amazon/dynamodb-local](https://hub.docker.com/r/amazon/dynamodb-local) image containing the tables `Jobs` and `Applications` and publish it to the ECR repository with URI `123456789123.dkr.ecr.ap-southeast-2.amazonaws.com/my-ecr-repository`:

```yml
steps:
  - label: Publish Dynamo Image
    plugins:
      - seek-oss/dynamodb-image#v1.2.0:
          tables:
            - Jobs
            - Applications
          repository: 123456789123.dkr.ecr.ap-southeast-2.amazonaws.com/my-ecr-repository
```

To run DynamoDB on a specific port when a container is run with the image, the `port` argument can be provided. The following example would run DynamoDB on port `8007`:

```yml
steps:
  - label: Publish Dynamo Image
    plugins:
      - seek-oss/dynamodb-image#v1.2.0:
          tables:
            - Jobs
            - Applications
          repository: 123456789123.dkr.ecr.ap-southeast-2.amazonaws.com/my-ecr-repository
          port: 8007
```

## Tagging

The plugin tags images differently depending on whether the build is on a feature branch or the main branch:

- Feature branch builds will tag the image as `branch-BUILDKITE_BUILD_NUMBER`, e.g., `branch-4985` for a build with build number `4985`
- Main branch builds will tag the image with the `latest` tag

## Configuration

| Argument Name | Type                  | Description                                                 |
| ------------- | --------------------- | ----------------------------------------------------------- |
| `repository`  | `string` (required)   | The URI of the ECR repository to publish the image to.      |
| `tables`      | `string[]` (required) | The names of the DynamoDB tables.                           |
| `port`        | `number` (optional)   | The port that DynamoDB local will run on. Defaults to 8000. |

## License

MIT (see [LICENSE](LICENSE))
