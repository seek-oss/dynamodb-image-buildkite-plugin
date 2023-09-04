#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"
load "$PWD/hooks/functions"

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
  run read_tables_with_output 'TABLES'
  assert_output "my-table-0 my-table-1 my-table-2"
  assert_success
}

@test "read_tables throws when no tables are defined" {
  run read_tables 'TABLES'
  assert_output "A list of tables must be provided."
  assert_failure
}