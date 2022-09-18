#!/bin/bash

echo "project initialization $1"
mkdir -p -- "$1"
cd $1

mkdir -p -- "assets"

#controllers
echo "controller initialization"
mkdir -p -- "controllers"
cd controllers
touch controller.js

echo "const uuid = require('uuid')
class Controller {

    constructor(service) {
      this.service = service;
      this.getAll = this.getAll.bind(this);
      this.insert = this.insert.bind(this);
      this.update = this.update.bind(this);
      this.delete = this.delete.bind(this);
    }
  
    async getAll(req, res) {
      return res.status(200).send(await this.service.getAll(req.query));
    }
  
    async insert(req, res) {
      req.body.identifier = uuid.v4();
      let response = await this.service.insert(req.body);
      if (response.error) return res.status(response.statusCode).send(response);
      return res.status(201).send(response);
    }
  
    async update(req, res) {
      const { id } = req.body;
      let response = await this.service.update(id, req.body);
  
      return res.status(response.statusCode).send(response);
    }
  
    async delete(req, res) {
      const { id } = req.body;
  
      let response = await this.service.delete(id);
  
      return res.status(response.statusCode).send(response);
    }
  
  }
  
module.exports = Controller;
" > controller.js


cd ..
#routes
echo "routes initialization"
mkdir -p -- "routes"
cd routes
touch index.js
echo "const fileUpload = require('express-fileupload')
 

const routes = (app) => {
    app.use(fileUpload())
}

module.exports = routes" > index.js

#middleware
echo "middlewares initialization"
touch middlewares.js



cd ..
#utils
echo "utils initialization"
mkdir -p -- "utils"
cd utils
mkdir -p -- "database"
mkdir -p -- "models"
cd database
touch db.js

echo "const { Sequelize, DataTypes, Model } = require('sequelize')
const dotenv = require('dotenv')
dotenv.config()


const sequelize = new Sequelize(
    process.env.DATABASE_NAME, process.env.DATABASE_USERNAME, process.env.DATABASE_PASSWORD, {
        host: 'localhost',
        dialect: 'mysql'
})

exports.sequelize = sequelize
exports.DataTypes = DataTypes
exports.Model = Model" > db.js

touch migrations.js
echo "(async () => {

})()" > migrations.js
cd ../

touch functions.js
echo "
exports.codeError = (errorKey, path) => {
    let error
    switch(errorKey){
        case 'len':
            error = {field: path, code: 8}
            break;
        case 'is_null':
            error = {field: path, code: 1}
            break;
        case 'isEmail':
            error = {field: path, code: 4}
            break;

        case 'not_unique':
            error = {field: path, code: 10}
            break;
        default:
            error = {field: path, code: 500}
    }

    return error
}" > functions.js

cd ..

touch app.js
echo "const express = require('express')
const app = express()
const dotenv = require('dotenv')
const routes = require('./routes/index')
dotenv.config()


routes(app)


app.listen(process.env.PORT, () => {
    console.log('Server started')
})" > app.js


touch .env.example
echo "TOKEN_SECRET=
PORT=
DATABASE_NAME=
DATABASE_PASSWORD=
DATABASE_USERNAME=
ROOT_API=" > .env.example


touch config.js
echo "module.exports = {
    'root': __dirname,
    'assets': __dirname+'/assets',
    'controllers': __dirname+'/controllers',
    'services': __dirname+'/services',
    'models': __dirname+'/utils/models',
    'express': require('express'),
    'uuid': require('uuid'),
    'crypto': require('pbkdf2'),
    'jwt': require('jsonwebtoken'),
    'fonctions': __dirname+'/utils/functions.js'
}" > config.js


echo "services initialization"
mkdir -p -- "services"
cd services
touch service.js

echo "/*
  This class is an abstract class which will be extended by all the models
*/
const fonctions = require('../utils/functions')

class Service {
    constructor(model)
    {
        this.model = model;
        this.getAll = this.getAll.bind(this)
        this.insert = this.insert.bind(this)
        this.update = this.update.bind(this)
        this.delete = this.delete.bind(this)
    }


    async getAll()
    {
        try{
            let items = await this.model.findAll()
            return {
                error: false,
                statusCode: 200,
                data: items
            }

        }catch (errors){
            return {
                error: true,
                statusCode: 500,
                errors
            }
        }
    }

    async insert(data) {
        try {
          let item = await this.model.create(data);
          if (item)
            return {
              error: false,
              statusCode: 201,
              item
            };
        } catch (error) {
          let errorsArr = []
          for(let err of error.errors){
            errorsArr.push(fonctions.codeError(err.validatorKey, err.path))
          }
          
          return {
            error: true,
            statusCode: 400,
            message: error.errmsg || \"Not able to create item\",
            errors: errorsArr
          };
        }
      }


    async update(id, data) {
        try {
          let item = await this.model.findByPk(id);
          if(!item)
          {
              return {
                  error: true,
                  statusCode: 404,
                  message: \"Item not found\"
              }
          }
          item.set(data)
          await item.save()
          return {
            error: false,
            statusCode: 202,
            item
          };
        } catch (error) {
          console.log(error)
          return {
            error: true,
            statusCode: 500,
            error
          };
        }
    }

    async delete(id) {
        try {
          let item = await this.model.findByPk(id);
          if (!item)
            return {
              error: true,
              statusCode: 404,
              message: \"item not found\"
            };
        
          await item.destroy()
    
          return {
            error: false,
            deleted: true,
            statusCode: 202,
            item
          };
        } catch (error) {
          return {
            error: true,
            statusCode: 500,
            error
          };
        }
    }
}

module.exports = Service" > service.js


cd ..
echo "package.json initialization"
touch package.json

echo "{
  \"name\": \"$1\",
  \"version\": \"1.0.0\",
  \"description\": \"\",
  \"main\": \"index.js\",
  \"scripts\": {
    \"test\": \"echo 'Error: no test specified' && exit 1\",
    \"dev\": \"nodemon app.js\",
    \"migrate\": \"node ./utils/database/migrations.js\"
  },
  \"author\": \"\",
  \"license\": \"ISC\",
  \"dependencies\": {
    \"body-parser\": \"^1.20.0\",
    \"dotenv\": \"^16.0.0\",
    \"express-fileupload\": \"^1.3.1\",
    \"jsonwebtoken\": \"^8.5.1\",
    \"mysql2\": \"^2.3.3\",
    \"nodemailer\": \"^6.7.5\",
    \"nodemon\": \"^2.0.15\",
    \"pbkdf2\": \"^3.1.2\",
    \"sequelize\": \"^6.19.0\",
    \"twilio\": \"^3.77.0\",
    \"uuid\": \"^8.3.2\"
  }
}
" > package.json

npm install