FROM amazon/dynamodb-local
COPY --chown=dynamodblocal ./tmp/shared-local-instance.db /home/dynamodblocal
COPY --chown=dynamodblocal ./dynamo /home/dynamodblocal/dynamo
ARG PORT
ENV DYNAMO_PORT $PORT
EXPOSE $PORT
ENTRYPOINT [ "sh" ]
CMD ["/home/dynamodblocal/dynamo"]
