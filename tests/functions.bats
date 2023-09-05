#!/usr/bin/env bats

export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty
load "$BATS_PLUGIN_PATH/load.bash"
load "$PWD/hooks/functions"

mkdir -p "/plugin/hooks/tmp"

@test "check_null does not throw when an environment variable exists" {
  export BUILDKITE_BUILD_NUMBER="1234"
  run check_null BUILDKITE_BUILD_NUMBER
  assert_success
}

@test "check_null throws when an environment variable does not exist" {
  run check_null BUILDKITE_BUILD_NUMBER
  assert_failure
}

@test "check_null throws when an environment variable is empty" {
  export BUILDKITE_BUILD_NUMBER=""
  run check_null BUILDKITE_BUILD_NUMBER
  assert_failure
}

@test "read_tables reads the tables into an array" {
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

@test "retrieve_schemas should retrieve the schemas for each table using the aws cli" {
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
