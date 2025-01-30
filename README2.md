# Step to Step to complete task

1. Pull haskell docker linter docker image
    ```sh
    docker pull docker pull hadolint/hadolint
    ```
2. Run the hadolint linter 
    ```sh
    docker run --rm -i hadolint/hadolint < Dockerfile
    ```
3. Add Werkzeug==2.2.2 to requirements.txt so FLASK can work properly. [See here](https://stackoverflow.com/questions/77213053/why-did-flask-start-failing-with-importerror-cannot-import-name-url-quote-fr)