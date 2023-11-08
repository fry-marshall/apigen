#!/bin/bash

cd ..
#create the default root files
echo "create default root files ( .env, package.json, etc...)"

#tsconfig file
touch tsconfig.json
echo "{
  \"compilerOptions\": {
    \"target\": \"es2016\",                                  /* Set the JavaScript language version for emitted JavaScript and include compatible library declarations. */
    \"module\": \"commonjs\",                                /* Specify what module code is generated. */
    \"rootDir\": \".\",                                  /* Specify the root folder within your source files. */
    \"outDir\": \"./dist\",                                   /* Specify an output folder for all emitted files. */
    \"esModuleInterop\": true,                             /* Emit additional JavaScript to ease support for importing CommonJS modules. This enables 'allowSyntheticDefaultImports' for type compatibility. */
    \"forceConsistentCasingInFileNames\": true,            /* Ensure that casing is correct in imports. */
    \"strict\": true,                                      /* Enable all strict type-checking options. */
    \"noImplicitAny\": true,                            /* Enable error reporting for expressions and declarations with an implied 'any' type. */
    \"allowUnreachableCode\": false,                     /* Disable error reporting for unreachable code. */
    \"skipLibCheck\": true,                                 /* Skip type checking all .d.ts files. */
  }
}" > tsconfig.json


#env file
touch .env.example
echo "ACCESS_TOKEN_SECRET=
REFRESH_TOKEN_SECRET=
PORT=
HOST_NAME=
DATABASE_NAME=
DATABASE_PASSWORD=
DATABASE_USERNAME=
MAIL_HOST=
MAIL_PORT=
MAIL_USERNAME=
MAIL_PASSWORD=
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_NUMBER=
FCM_SERVER_KEY=" > .env.example

#package.json file
touch package.json
echo "{
  \"name\": \"$1\",
  \"version\": \"1.0.0\",
  \"description\": \"\",
  \"main\": \"app.js\",
  \"scripts\": {
    \"test\": \"jest --watchAll\",
    \"start\": \"npx tsc -w & nodemon dist/src/app.js\",
    \"migrate\": \"node dist/src/config/migrations.js\"
  },
  \"author\": \"\",
  \"license\": \"ISC\",
  \"dependencies\": {
  }
}
" > package.json

#Makefile
touch Makefile
echo "start: 
	npm run start
compile: 
	npx tsc
migrate: 
	npm run migrate
test: 
	tsc -w & npm run test --watch" > Makefile


#jest.config.ts
touch jest.config.ts
echo "module.exports = {
    preset: 'ts-jest',
    testEnvironment: 'node',
    moduleNameMapper: {
      \"@exmpl/(.*)\": \"./$1\"
    },
};" > jest.config.ts


#.gitignore
touch .gitignore
echo "node_modules
dist/src
dist/jest.config.js" > .gitignore
