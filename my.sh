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

echo "const utils = require('../utils/functions')

exports.verifyToken = (jwt /* ,token_black_list */) => {
  return async (req, res, next) => {
    const authHeader = req.headers['authorization']
    const token = authHeader && authHeader.split(' ')[1]


    if (token == null) return res.status(401).send(utils.inputErrors('').token_invalid)

    jwt.verify(token, process.env.ACCESS_TOKEN_SECRET, async (err, user) => {


      /* let token_ = await token_black_list.findOne({
          where: {
              token: token
          }
      })*/

      if (err /*|| typeof token_ !== 'undefined'*/) {
        return res.status(401).send(utils.inputErrors('').token_expired)
      } else {
        res.locals.id = user.id
        res.locals.token = token
        next()
      }



    })
  }
}


exports.verifyRights = (rights, account) => {
  return async (req, res, next) => {
    let account_ = await account.findByPk(res.locals.id)

    if (!account_) {
      return res.status(404).send(utils.inputErrors('').account_not_found)
    }

    if (account_.account_type !== rights) {
      return res.status(403).send(utils.inputErrors('').access_denied)
    }

    res.locals.account = account_
    next()
  }
}

exports.socketIo = (io) => {
  return (req, res, next) => {
    res.locals.io = io
    next()
  }
}" > middlewares.js



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
}

exports.inputErrors = (path) => {
    return {
        required: { field: path, type: 400, subtype: 1, msg: 'required' },
        invalid_format: { field: path, type: 400, subtype: 2, msg: 'invalid_format' },
        incorrect_select: { field: path, type: 400, subtype: 3, msg: 'incorrect_select' },
        incorrect_length: { field: path, type: 400, subtype: 4, msg: 'incorrect_length' },
        not_unique: { field: path, type: 400, subtype: 5, msg: 'not_unique' },
        global: { field: path, type: 400, subtype: 6, msg: 'unknown' },
        incorrect_value: { field: path, type: 400, subtype: 7, msg: 'incorrect value' },

        account_not_found: { type: 404, subtype: 1, msg: 'account not found' },
        element_not_found: { type: 404, subtype: 2, msg: 'element not found' },
        token_invalid: { type: 401, subtype: 1, msg: 'token invalid' },
        token_expired: { type: 401, subtype: 2, msg: 'token expired' },

        access_denied: { type: 403, subtype: 1, msg: 'acces denied' },
    }
}


exports.validPassword = (password) => {
    if(password.trim() === ''){
        return {error: true, ...this.inputErrors("password").required}
    }
    else if(password.length < 8 || password.length > 32){
        return {error: true, ...this.inputErrors("password").invalid_format}
    }
    else{
        return {error: false}
    }
}


exports.generateDigits = () => Math.floor(Math.random() * 999999 + 100000)
exports.generateExpiredTime = (time = 600) => Math.floor(Date.now() / 1000) + time

exports.formatDate = (weeks = null, date = new Date()) => {
    if(weeks !== null){
        date.setDate(date.getDate() + weeks * 7)
    }
    const day = date.getDate()
    const year = date.getFullYear()
    const month = date.getMonth()+1
    const hours = date.getHours()
    const minutes = date.getMinutes()
    const secondes = date.getSeconds()

    const format = year+'-'+month+'-'+day+' '+hours+':'+minutes+':'+secondes
    return format
}

exports.formatOnlyDate = (weeks = null, date = new Date()) => {
    if(weeks !== null){
        date.setDate(date.getDate() + weeks * 7)
    }
    const day = date.getDate()
    const year = date.getFullYear()
    const month = date.getMonth()+1
   

    const format = year+'-'+month+'-'+day
    return format
}


exports.getMonday = () => {
    let curr = new Date();
    let first = curr.getDate() - curr.getDay() + 1;

    return this.formatOnlyDate(null, new Date(curr.setDate(first)));
}


exports.getSunday = () => {
    let curr = new Date();
    let first = curr.getDate() - curr.getDay() + 1;
    let last = first + 6;

    return this.formatOnlyDate(null, new Date(curr.setDate(last)));
}

" > functions.js

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
echo "ACCESS_TOKEN_SECRET=
REFRESH_TOKEN_SECRET=
PORT=
DATABASE_NAME=
DATABASE_PASSWORD=
DATABASE_USERNAME=
ROOT_API=
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=" > .env.example


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
echo "router and migration auto generate"
touch router.js
touch migration.js
echo "var fs = require('fs');

const myArgs = process.argv.slice(2);
const route = \"\\\"/\"+myArgs+\"\\\"\"
const routerName = myArgs+\"Router\"

const requireName = 'require(\"./'+myArgs+'/'+myArgs+'\")'
const importName = 'const ' + routerName + ' = ' + requireName

var data = fs.readFileSync('routes/index.js').toString().split(\"\n\");
let lineRouter
let lineImport

let alreadyImport = false
let alreadyRouterAdded = false


for(let i = 0; i < data.length; i++){
    if(data[i].includes(importName)){
        alreadyImport = true
    }

    if(data[i].includes('\tapp.use('+route+', '+routerName+')')){
        alreadyRouterAdded = true
    }
}


if(!alreadyImport || !alreadyRouterAdded){
    for(let i = 0; i < data.length; i++){
        if(data[i].includes('}')){
            lineRouter = i
        }
        
        if(!alreadyImport){
            if(data[i].includes('fileUpload = ')){
                lineImport = i
            }
        }
        
    }
    
    
    data.splice(lineRouter, 0,'\tapp.use('+route+', '+routerName+')');
    data.splice(lineImport, 0, ''+importName+'');
    var text = data.join(\"\n\");
    
    fs.writeFile('routes/index.js', text, function (err) {
      if (err) return console.log(err);
    });
}" > router.js


echo "var fs = require('fs');
const myArgs = process.argv.slice(2);
const requireName = 'require(\"../models/'+myArgs+'\")'
const importName = 'const '+myArgs+' = '+ requireName
const sync = 'await '+myArgs+'.sync()'
var data = fs.readFileSync('utils/database/migrations.js').toString().split(\"\n\");
let line
let alreadyImport = false


for(let i = 0; i < data.length; i++){
    if(data[i].includes(importName)){
        alreadyImport = true
    }
}


if(!alreadyImport){
    for(let i = 0; i < data.length; i++){
        if(data[i].includes('}')){
            line = i
        }
       
    }
    
    
    data.splice(line, 0, '\t'+sync+'');
    data.splice(line, 0, '\t'+importName+'');

    var text = data.join(\"\n\");
    
    fs.writeFile('utils/database/migrations.js', text, function (err) {
      if (err) return console.log(err);
    });
}
" > migration.js



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
    \"express\": \"^4.18.2\",
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


