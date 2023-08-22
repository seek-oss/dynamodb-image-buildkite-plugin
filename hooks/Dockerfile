FROM amazon/dynamodb-local
COPY --chown=dynamodblocal ./tmp/shared-local-instance.db /home/dynamodblocal
EXPOSE 8003
CMD ["-jar", "DynamoDBLocal.jar", "-port", "8003", "-sharedDb"]