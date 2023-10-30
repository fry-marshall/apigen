#!/bin/bash

#test
cd tests
touch $1".test.ts"

echo "import serverApp from \"../app\";
import http from \"http\";

let server: http.Server;

beforeAll(() => {
    server = serverApp
})

describe(\"$1\", () => {})" >$1".test.ts"