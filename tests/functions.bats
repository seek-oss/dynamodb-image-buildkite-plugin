#!/usr/bin/env bats

export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty
load "$BATS_PLUGIN_PATH/load.bash"
load "$PWD/hooks/functions"

mkdir -p "/plugin/hooks/tmp"

@test "check_null: does not throw when an environment variable exists" {
  export BUILDKITE_BUILD_NUMBER="1234"
  run check_null BUILDKITE_BUILD_NUMBER
  assert_success
}

@test "check_null: throws when an environment variable does not exist" {
  run check_null BUILDKITE_BUILD_NUMBER
  assert_failure
}

@test "check_null: throws when an environment variable is empty" {
  export BUILDKITE_BUILD_NUMBER=""
  run check_null BUILDKITE_BUILD_NUMBER
  assert_failure
}

@test "read_tables: reads the tables into an array" {
  export BUILDKITE_PLUGIN_DYNAMODB_IMAGE_TABLES_0="my-table-0"
  export BUILDKITE_PLUGIN_DYNAMODB_IMAGE_TABLES_1="my-table-1"
  export BUILDKITE_PLUGIN_DYNAMODB_IMAGE_TABLES_2="my-table-2"
  run read_tables_with_output
  assert_output "my-table-0 my-table-1 my-table-2"
  assert_success
}

@test "read_tables throws when no tables are defined" {
  run read_tables
  assert_output "A list of tables must be provided."
  assert_failure
}

@test "retrieve_schemas: should retrieve the schemas for each table using the aws cli" {
  stub aws \
    "dynamodb describe-table --table-name my-table-0 --output json : echo {"TableName": "my-table-0"}" \
    "dynamodb describe-table --table-name my-table-1 --output json : echo {"TableName": "my-table-1"}" \
    "dynamodb describe-table --table-name my-table-2 --output json : echo {"TableName": "my-table-2"}"

  local test_tables=("my-table-0" "my-table-1" "my-table-2")
  run retrieve_schemas "${test_tables[@]}"

  assert_output --partial {TableName: my-table-0}
  assert_output --partial {TableName: my-table-1}
  assert_output --partial {TableName: my-table-2}
  assert_success

  unstub aws
}

@test "generate_create_json: pulls out all required fields from the schema" {
  local test_file="/plugin/mock/TestTableNoIndexes.json"
  run generate_create_json ${test_file}

  assert_output --partial '"TableName": "SampleTable"'
  assert_output --partial '"KeySchema": [ { "AttributeName": "ID", "KeyType": "HASH" }, { "AttributeName": "Name", "KeyType": "RANGE" } ]'
  assert_output --partial '"AttributeDefinitions": [ { "AttributeName": "ID", "AttributeType": "N" }, { "AttributeName": "Name", "AttributeType": "S" } ]'
  assert_success
}

@test "generate_create_json: ignores the schema billing mode and always sets it to PAY_PER_REQUEST" {
  local test_file="/plugin/mock/TestTableNoIndexes.json"
  run generate_create_json ${test_file}

  assert_output --partial '"BillingMode": "PAY_PER_REQUEST"'
  assert_success
}

@test "generate_create_json: includes the GSI when it is present" {
  local test_file="/plugin/mock/TestTableGSI.json"
  run generate_create_json ${test_file}

  assert_output --partial '"GlobalSecondaryIndexes": [ { "IndexName": "TestTableGSI", "KeySchema": [ { "AttributeName": "SecondaryID", "KeyType": "HASH" } ], "Projection": { "ProjectionType": "ALL" } } ]'
  assert_success
}

@test "generate_create_json: includes the LSI when it is present" {
  local test_file="/plugin/mock/TestTableLSI.json"
  run generate_create_json ${test_file}

  assert_output --partial '"LocalSecondaryIndexes": [ { "IndexName": "TestTableLSI", "KeySchema": [ { "AttributeName": "TernaryID", "KeyType": "HASH" } ]'
  assert_success
}

@test "create_database: creates each of the tables locally and saves the resulting database" {
  local test_tables=("my-table-0" "my-table-1" "my-table-2")

  stub aws \
    "dynamodb create-table --cli-input-json /plugin/hooks/tmp/my-table-0.json --region "local" --endpoint http://localhost:56789 : echo create my-table-0" \
    "dynamodb create-table --cli-input-json /plugin/hooks/tmp/my-table-1.json --region "local" --endpoint http://localhost:56789 : echo create my-table-1" \
    "dynamodb create-table --cli-input-json /plugin/hooks/tmp/my-table-2.json --region "local" --endpoint http://localhost:56789 : echo create my-table-2" \
    "dynamodb list-tables --region "local" --endpoint http://localhost:56789 : echo listing tables"

  stub docker \
    "pull amazon/dynamodb-local:latest : echo pulled amazon/dynamodb-local:latest" \
    "run -d -p 0:8000 amazon/dynamodb-local:latest -jar DynamoDBLocal.jar -port 8000 -sharedDb : echo 123456789" \
    "port 123456789 8000 : echo 0.0.0.0:56789" \
    "cp 123456789:/home/dynamodblocal/shared-local-instance.db /plugin/hooks/tmp/shared-local-instance.db : echo copied database" \
    "stop 123456789 : echo stopped local dynamo" 

  stub sleep \
    "5 : echo sleeping for 5 seconds while dynamo starts"

  function generate_create_json() {
    local input_json_file="$1"
    echo "${input_json_file}"
  }

  run create_database "${test_tables[@]}"

  assert_output --partial "pulled amazon/dynamodb-local:latest"
  assert_output --partial "sleeping for 5 seconds while dynamo starts"
  assert_output --partial "create my-table-0"
  assert_output --partial "create my-table-1"
  assert_output --partial "create my-table-2"
  assert_output --partial "listing tables"
  assert_output --partial "copied database"
  assert_output --partial "stopped local dynamo"
  assert_success

  unstub aws
  unstub docker
  unstub sleep
}

@test "build_and_publish: builds and publishes the image with a build number branch tag when on a branch" {
  export BUILDKITE_PIPELINE_DEFAULT_BRANCH="master"
  export BUILDKITE_BRANCH="my-branch"
  export BUILDKITE_BUILD_NUMBER="1234"
  export BUILDKITE_PLUGIN_DYNAMODB_IMAGE_REPOSITORY="my-registry/my-image"

  stub docker \
    "buildx create --use : echo creating builder instance" \
    "buildx build --push --no-cache --file /plugin/hooks/Dockerfile --platform linux/arm64,linux/amd64 --build-arg PORT=8000 --tag my-registry/my-image:branch-1234 . : echo building and publishing branch image" \
    "buildx rm : echo removing builder instance"

  run build_and_publish

  assert_output --partial "creating builder instance"
  assert_output --partial "building and publishing branch image"
  assert_output --partial "removing builder instance"
  assert_success

  unstub docker
}

@test "build_and_publish: builds and publishes the image with the latest tag and a build number tag when on the main branch" {
  export BUILDKITE_PIPELINE_DEFAULT_BRANCH="master"
  export BUILDKITE_BRANCH="master"
  export BUILDKITE_BUILD_NUMBER="1234"
  export BUILDKITE_PLUGIN_DYNAMODB_IMAGE_REPOSITORY="my-registry/my-image"

  stub docker \
    "buildx create --use : echo creating builder instance" \
    "buildx build --push --no-cache --file /plugin/hooks/Dockerfile --platform linux/arm64,linux/amd64 --build-arg PORT=8000 --tag my-registry/my-image:latest --tag my-registry/my-image:1234 . : echo building and publishing latest image" \
    "buildx rm : echo removing builder instance"

  run build_and_publish

  assert_output --partial "creating builder instance"
  assert_output --partial "building and publishing latest image"
  assert_output --partial "removing builder instance"
  assert_success

  unstub docker
}
