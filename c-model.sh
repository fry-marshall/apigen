#!/bin/bash

cd utils/models
touch $1".js"

capitalize="$(tr '[:lower:]' '[:upper:]' <<< ${1:0:1})${1:1}"

echo "
const db = require('../database/db')
const sequelize = db.sequelize

class $capitalize extends db.Model {}

$capitalize.init({
    identifier: {
        type: db.DataTypes.UUID,
        primaryKey: true
    },
   
}, {
    sequelize,
    modelName: '$1'
})

module.exports = $capitalize
" > $1".js"



#services
cd ../../services
touch $1"-service.js"

serviceClass=$capitalize"Service"

echo "const Service = require('./service')

class $serviceClass extends Service
{
    constructor(model)
    {
        super(model)
    }
}


module.exports = $serviceClass" > $1"-service.js"


#controllers
cd ../controllers
touch $1"-controller.js"
controllerClass=$capitalize"Controller"

echo "
const config = require('../config')
const model = require(config.models+'/$1')
const Controller = require(config.controllers+'/controller')
const ServiceClass = require(config.services+'/$1-service')
const $1Service = new ServiceClass(model);
const path = require('path')
  
class $controllerClass extends Controller {
  
    constructor(service) {
        super(service);
    }  
}
  
module.exports = new $controllerClass($1Service);
" > $1"-controller.js"



#routes
cd ../routes
mkdir -p -- $1
cd $1
touch $1".js"
touch middlewares.js
echo "const config = require('../../config')

const $controllerClass = require(config['controllers']+'/$1-controller')
const expressRouter = config.express.Router()
const bodyParser = require('body-parser');


var jsonParser = bodyParser.json()


expressRouter.post('/create', jsonParser, $controllerClass.insert)
expressRouter.get('/', $controllerClass.getAll)
expressRouter.put('/update',jsonParser,$controllerClass.update)
expressRouter.delete('/delete',jsonParser, $controllerClass.delete)


module.exports = expressRouter" > $1".js"


#index.js
#add the route to the index
cd ../..
node router.js $1
node migration.js $1