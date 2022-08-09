#!/bin/bash

mkdir -p -- "assets"
#controllers
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
      
      req.query.identifier = uuid.v4();
      let response = await this.service.insert(req.query);
      if (response.error) return res.status(response.statusCode).send(response);
      return res.status(201).send(response);
    }
  
    async update(req, res) {
      const { id } = req.params;
  
      let response = await this.service.update(id, req.query);
  
      return res.status(response.statusCode).send(response);
    }
  
    async delete(req, res) {
      const { id } = req.params;
  
      let response = await this.service.delete(id);
  
      return res.status(response.statusCode).send(response);
    }
  
  }
  
module.exports = Controller;" > controller.js


cd ..
#routes
mkdir -p -- "routes"
cd routes
touch index.js
echo "const fileUpload = require('express-fileupload')
 

const routes = (app) => {
    app.use(fileUpload())
}

module.exports = routes" > index.js

touch middlewares.js
echo "
exports.verifyToken = (jwt, token_black_list) => {
    return async (req, res, next) => {
        const authHeader = req.headers['authorization']
        const token = authHeader && authHeader.split(' ')[1]

    
        if (token == null) return res.sendStatus(401)
      
        jwt.verify(token, process.env.TOKEN_SECRET, async (err, user) => {

      
          if (err) return res.sendStatus(23)

          
          /* let token_ = await token_black_list.findOne({
              where: {
                  token: token
              }
          })



          if(typeof token_ !== 'undefined')
          {
            return res.status(400).json({ errors: [{code: 4, param: 'invalid token'}] });
          } */

      
          res.locals.user = user
          res.locals.token = token
        })
        next()
    }
}


exports.errors = (validationResult) => {
    return (req, res, next) => {
        const errors = validationResult(req).array().filter(err => {
            return err.msg.includes('code')
        });
        if (errors.length !== 0) {
            return res.status(400).json({ errors: errors });
        }
        next()
    }
}


exports.isEmpty = (val) => {
    if(val.trim() === '')
    {
        throw new Error(JSON.stringify({code: 3}));
    }
    return true
}

exports.isNull = (val) => {
    if(typeof val === 'undefined')
    {
        throw new Error(JSON.stringify({code: 1}));
    }
    return true
}

exports.isNullAndEmpty = (val) => {
    if(typeof val === 'undefined')
    {
        throw new Error(JSON.stringify({code: 1}));
    }
    else {
        if(val.trim() === '')
        {
            throw new Error(JSON.stringify({code: 3}));
        }
    }
    return true
}

exports.isImageNull = (req, res, next) => {
    if(typeof req.files === 'undefined' || typeof req.files.image === 'undefined')
    {
        return res.status(400).json({ errors: [{code: 1, param: 'image'}] });
    }
    next()
}


exports.isEmailNullForCP = (req, res, next) => {
    if(req.query.account_type === 'CP' && typeof req.query.email === 'undefined')
    {
        return res.status(400).json({ errors: [{code: 1, param: 'email'}] });
    }
    next()
}


exports.isEmail = (req, res, next) => {
    let regexp = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
    if(!req.query.email.match(regexp))
    {
        return res.status(400).json({ errors: [{code: 2, param: 'email'}] });
    }
    next()
}


exports.isPhoneNumber = (val) => {
    let regexp = /^\d{10}$/;
    if(val.match(regexp))
    {
        return true
    }
    else{
        throw new Error(JSON.stringify({code: 4}));
    }    
}


exports.isLength = (val) => {
    
    if(val.length >= 8)
    {
        return true
    }
    else{
        throw new Error(JSON.stringify({code: 8}));
    }    
}" > middlewares.js


cd ..
#utils
mkdir -p -- "utils"
cd utils
mkdir -p -- "database"
mkdir -p -- "models"
cd database
touch db.js
touch migrations.js
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
cd ../..


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
    'slugify': require('slugify'),
    'crypto': require('pbkdf2'),
    'jwt': require('jsonwebtoken'),
}" > config.js



mkdir -p -- "services"
cd services
touch service.js

echo "/*
  This class is an abstract class which will be extended by all the models
*/

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
          return {
            error: true,
            statusCode: 500,
            message: error.errmsg || \"Not able to create item\",
            errors: error.errors
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