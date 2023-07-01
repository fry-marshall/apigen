#!/bin/bash

echo "project initialization $1"
mkdir -p -- "$1"
cd $1

mkdir -p -- "src"
cd src
mkdir -p -- "app"
cd app

#controllers
echo "controllers initialization"
mkdir -p -- "controllers"
cd controllers
touch controller.ts

echo "import Service from \"../services/service\";
import Express from \"express\"
import { v4 as uuidv4 } from \"uuid\";

class Controller {

    protected service: Service

    constructor(service: Service) {
      this.service = service;
      this.getAll = this.getAll.bind(this);
      this.insert = this.insert.bind(this);
      this.update = this.update.bind(this);
      this.delete = this.delete.bind(this);
    }
  
    async getAll(req: Express.Request, res: Express.Response) {
        return res.status(200).send(await this.service.getAll());
    }
  
    async insert(req: Express.Request, res: Express.Response) {
      req.body.id = uuidv4();
      let response = await this.service.insert(req.body);
      if ( response?.is_error ){
        return res.status(400).send(response);
      }
      return res.status(201).send(response);
    }
  
    async update(req: Express.Request, res: Express.Response) {
      const { id } = req.body;
      let response = await this.service.update(id, req.body);

      if ( response?.is_error ){
        return res.status(400).send(response);
      }

      return res.status(202).send(response);
    }
  
    async delete(req: Express.Request, res: Express.Response) {
      const { id } = req.body;
  
      let response = await this.service.delete(id);

      if ( response?.is_error ){
        return res.status(400).send(response);
      }
  
      return res.status(202).send(response);
    }
  
}

export default Controller
" > controller.ts


cd ..
#routes
echo "routes initialization"
mkdir -p -- "routes"
cd routes
touch router.ts
echo "import express from \"express\"
import { Express as ExpressFR } from \"express\"

const router = (app: ExpressFR) => {
    app.use(express.urlencoded({ extended: true }))
}

export default router" > router.ts

#middleware
echo "middlewares initialization"
touch middlewares.ts



cd ..
#models
echo "models initialization"
mkdir -p -- "models"
cd models
mkdir -p -- "interfaces"
cd interfaces

touch errors.ts
echo "export interface ErrorAttributes{
    name?: string;
    status?: number,
    message?: string
}

export interface ApiErrorAttributes{
   error?: ErrorAttributes
   fiedls?: ErrorAttributes[]
}


export const defaultApiErrorValue: ApiErrorAttributes = {
    error: {
        name: 'unknown_error',
        status: 500,
    }
}" > errors.ts


touch responses.ts
echo "import { ApiErrorAttributes } from \"./errors\";

export interface ResponseRequest{
    is_error?: boolean;
    value: ApiErrorAttributes | ValidResponse 
}

export interface ValidResponse{
    status?: number;
    data: any
}" > responses.ts

cd ../..



echo "services initialization"
mkdir -p -- "services"
cd services
touch services.ts

echo "import { ModelStatic, ValidationError } from \"sequelize\";
import { codeErrors } from \"../../config/helpers\";
import { ApiErrorAttributes, defaultApiErrorValue } from \"../models/interfaces/errors\";
import { ResponseRequest } from \"../models/interfaces/responses\";


class Service {

    protected model: ModelStatic<any>

    constructor(model: ModelStatic<any>) {
        this.model = model;
        this.getAll = this.getAll.bind(this)
        this.insert = this.insert.bind(this)
        this.update = this.update.bind(this)
        this.delete = this.delete.bind(this)
    }


    async getAll() {
        try {
            let data = await this.model.findAll()
            return {is_error: false, value: data} as ResponseRequest

        } catch (errors) {
            return {is_error: true, value: defaultApiErrorValue} as ResponseRequest
        }
    }

    async insert(data: any) {
        try {
            let item = await this.model.create(data);
            if (item)
                return {is_error: false, value: item} as ResponseRequest
        } catch (error: any) {
            if(error instanceof ValidationError){
                let fieldErrors = []

                for (let err of error.errors) {
                    fieldErrors.push(codeErrors(err.validatorKey!, err.path!))
                }

                const validationErrors: ApiErrorAttributes = { error: { name: 'bad_request', status: 400 }, fiedls: fieldErrors}
                return {is_error: true, value: validationErrors} as ResponseRequest
            }

            return {is_error: true, value: defaultApiErrorValue} as ResponseRequest
            
        }
    }


    async update(id: string, data: any) {
        try {
            let item = await this.model.findByPk(id);
            if (!item) {
                const validationErrors = { error: { name: 'not_found', status: 404, message: 'Item not found' }}
                return {is_error: true, value: validationErrors} as ResponseRequest
            }
            item.set(data)
            await item.save()
            return {is_error: false, value: item} as ResponseRequest
        } catch (error) {
            return {is_error: true, value: defaultApiErrorValue} as ResponseRequest
        }
    }

    async delete(id: string) {
        try {
            let item = await this.model.findByPk(id);
            if (!item){
                const validationErrors = { error: { name: 'not_found', status: 404, message: 'Item not found' }}
                return {is_error: true, value: validationErrors} as ResponseRequest
            }

            await item.destroy()
            return {is_error: false, value: item} as ResponseRequest
        } catch (error) {
            return {is_error: true, value: defaultApiErrorValue} as ResponseRequest
        }
    }
}

export default Service" > service.ts


cd ../..


#assets
echo "assets initialization"
mkdir -p -- "assets"
cd assets
touch assets.ts

cd ..

#config
echo "config initialization"
mkdir -p -- "config"
cd config

touch database.ts
echo "import { Sequelize } from \"sequelize\";
import 'dotenv/config';

const sequelize = new Sequelize(process.env.DATABASE_NAME as string, process.env.DATABASE_USERNAME as string, process.env.DATABASE_PASSWORD, {
  host: 'localhost',
  dialect: 'mysql',
});

export default sequelize;" > database.ts

touch helpers.ts
echo "import { ErrorAttributes } from \"../app/models/interfaces/errors\";


function codeErrors(key: string, path: string){
    let error: ErrorAttributes = {}
    error.name = path

    switch(key){
        case 'is_null':
            error.status = 1
            break;
        case 'isEmail':
            error.status = 4
            break;
        case 'len':
            error.status = 8
            break;
        case 'not_unique':
            error.status = 10
            break;
        default:
            error.status = 500
    }

    return error

}

export { codeErrors } " > helpers.ts

touch migrations.ts
echo "
(async () => {
})();" > migrations.ts

cd ..
touch app.ts
echo "import Express from \"express\"
import router from \"./app/routes/router\"
import http from \"http\"


const app = Express()
const server = new http.Server(app)

router(app)

/*
  To add asset routes
  app.use('/assets/asset_route', Express.static('assets/asset_folder'))
*/

server.listen(process.env.PORT, () => {
    console.log('Server started')
})" > app.ts


cd ..


#ts config
touch tsconfig.json
echo "{
    \"compilerOptions\": {
      \"target\": \"es2016\", 
      \"module\": \"commonjs\",
      \"outDir\": \"./dist\", // Définit le dossier de sortie des fichiers JavaScript compilés
      \"rootDir\": \"./src\",
      \"forceConsistentCasingInFileNames\": true,
      \"strict\": true,
      \"skipLibCheck\": true,
      \"esModuleInterop\": true,
    },
    \"exclude\": [
      \"node_modules\" // Exclut le dossier node_modules de la compilation
    ],
    \"include\": [
      \"**/*.ts\" // Inclut tous les fichiers TypeScript du projet, y compris les dossiers vides
    ],
    \"paths\": {
      \"app/*\": [\"./src/app/*\"],
      \"config/*\": [\"./src/config/*\"],
  },
}" > tsconfig.json


#env file
touch .env.example
echo "ACCESS_TOKEN_SECRET=
REFRESH_TOKEN_SECRET=
PORT=
DATABASE_NAME=
DATABASE_PASSWORD=
DATABASE_USERNAME=
ROOT_API=
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=" > .env.example


#package json
echo "package.json initialization"
touch package.json
echo "{
  \"name\": \"$1\",
  \"version\": \"1.0.0\",
  \"description\": \"\",
  \"main\": \"app.js\",
  \"scripts\": {
    \"test\": \"echo 'Error: no test specified' && exit 1\",
    \"dev\": \"tsc -w & nodemon dist/app.js\",
    \"migrate\": \"node dist/config/migrations.js\"
  },
  \"author\": \"\",
  \"license\": \"ISC\",
  \"dependencies\": {
  }
}
" > package.json

npm install
npm i @types/multer @types/node @types/uuid dotenv express multer sequelize typescript uuid
npm i -D @types/express