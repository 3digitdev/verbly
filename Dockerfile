# Use the official lightweight Python image.
# https://hub.docker.com/r/nimlang/nim
FROM nimlang/nim

# Copy local code to the container image.
ENV APP_HOME /app
WORKDIR $APP_HOME
ADD src/nim/api src/nim/api/
COPY data/verbly.db data/verbly.db
COPY run.sh .

# Compile Source
WORKDIR src/nim/api
RUN nimble install -y

# Start the API
WORKDIR $APP_HOME
RUN chmod +x /app/run.sh
ENTRYPOINT ["/app/run.sh"]
