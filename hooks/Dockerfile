FROM amazon/dynamodb-local
COPY --chown=dynamodblocal ./tmp/shared-local-instance.db /home/dynamodblocal
EXPOSE 8000
CMD ["-jar", "DynamoDBLocal.jar", "-sharedDb"]