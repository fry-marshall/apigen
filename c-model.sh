#!/bin/bash

cd utils/models
touch $1".js"

capitalize="$(tr '[:lower:]' '[:upper:]' <<<${1:0:1})${1:1}"

if [ $1 == "account" ] && [ $2 == "--default" ]; then
echo "const db = require('../database/db')
const sequelize = db.sequelize

class $capitalize extends db.Model {}

$capitalize.init({
    identifier: {
        type: db.DataTypes.UUID,
        primaryKey: true
    },
    phone: {
        type: db.DataTypes.STRING,
        allowNull: false,
        unique: true,
        validate: {
            notEmpty: true,
        }
    },
    phone_verified_digits: {
        type: db.DataTypes.STRING,
        allowNull: false,
        notEmpty: true
    },
    phone_expiredtime: {
        type: db.DataTypes.STRING,
        allowNull: false
    },
    phone_verified: {
        type: db.DataTypes.BOOLEAN,
        defaultValue: false
    },
    email: {
        type: db.DataTypes.STRING,
        unique: true,
        validate: {
            isEmail: true,
        }
    },
    email_verified_digits: {
        type: db.DataTypes.STRING,
    },
    email_expiredtime: {
        type: db.DataTypes.STRING,
    },
    email_verified: {
        type: db.DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false
    },
    password: {
        type: db.DataTypes.STRING,
        allowNull: false,
        validate: {
            notEmpty: true
        }
    },
    status: {
        type: db.DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false
    },
   
}, {
    sequelize,
    modelName: 'account'
})

module.exports = $capitalize" >$1".js"


echo "const db = require('../database/db')
const sequelize = db.sequelize

class Tokenblacklist extends db.Model {}

Tokenblacklist.init({
    identifier: {
        type: db.DataTypes.UUID,
        primaryKey: true
    },
    token: {
        type: db.DataTypes.STRING,
        allowNull: false,
        unique: true,
    },  
   
}, {
    sequelize,
    modelName: 'tokenblacklist'
})

module.exports = Tokenblacklist" > "tokenblacklist.js"

else
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

module.exports = $capitalize" >$1".js"
fi

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


module.exports = $serviceClass" >$1"-service.js"

#controllers
cd ../controllers
touch $1"-controller.js"
controllerClass=$capitalize"Controller"

if [ $1 == "account" ] && [ $2 == "--default" ]; then
echo "
const config = require('../config')
const model = require(config.models+'/account')
const Controller = require(config.controllers+'/controller')
const ServiceClass = require(config.services+'/account-service')
const accountService = new ServiceClass(model);
const path = require('path')
const utils = require('../utils/functions')
const tokenblacklist = require(config.models + '/tokenblacklist')
const twilio = require('twilio')(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

  
class $controllerClass extends Controller {
  
    constructor(service) {
        super(service);
    }  


    // to create an account
    async insert(req, res) {

        try {

            req.body.identifier = config.uuid.v4()
            const passwordError = utils.validPassword(req.body.password)
            if (passwordError.error) {
                return res.status(400).send(passwordError)
            }

            req.body.password = config.crypto.pbkdf2Sync(req.body.password, 'salt', 1, 32, 'sha512').toString('hex')
            req.body.phone_verified_digits = Math.floor(Math.random() * 999999 + 100000)
            req.body.phone_expiredtime = Math.floor(Date.now() / 1000) + 600

            req.body.email_verified_digits = Math.floor(Math.random() * 999999 + 100000)
            req.body.email_expiredtime = Math.floor(Date.now() / 1000) + 600

            let response = await this.service.insert(req.body)
            if (response.error) return res.status(response.statusCode).send(response);

            const item = response.item


            return res.status(201).send({ msg: 'item created successfully' })


        } catch (e) {
            return res.status(500).send(utils.inputErrors("").global)
        }

    }

 

    // to log in an account
    async login(req, res) {
        try {

            let account = await model.findOne({
                where: {
                    // it could be email or phone ( depending on the project )
                    email: req.body.login,
                    password: config.crypto.pbkdf2Sync(req.body.password, 'salt', 1, 32, 'sha512').toString('hex')
                }
            })

            if (!account) {
                return res.status(404).json(utils.inputErrors("").account_not_found);
            }

            const token = config.jwt.sign({ id: account.identifier }, process.env.ACCESS_TOKEN_SECRET, { expiresIn: '1296000s' });
            return res.status(200).json({ token })

        } catch (err) {
            return res.status(500).send(utils.inputErrors("").global)
        }
    }

    // to log out an account
    async logout(req, res) {

        try {

            const authHeader = req.headers['authorization']
            const token = authHeader && authHeader.split(' ')[1]

            let tokenBlackListCreated = await tokenblacklist.create({
                identifier: config.uuid.v4(),
                token
            })

            return res.status(200).send({ msg: 'account logout successfully' })

        } catch (e) {
            return res.status(500).send(utils.inputErrors("").global)
        }

    }


    // to verify the phone number
    async verifyPhone(req, res) {

        try {

            let account = res.locals.account

            const expireTime = account.phone_expiredtime - Math.floor(Date.now() / 1000)
            if (expireTime <= 0) {
                return res.status(400).json(utils.inputErrors('token').token_expired)
            }

            if (req.body.verified_digits === account.phone_verified_digits) {
                account.phone_verified = 1

                await account.save()
                return res.status(202).send({ msg: 'phone verified succesfully' })
            }
            else {
                return res.status(400).json(utils.inputErrors('token').invalid_format)
            }

        } catch (e) {
            return res.status(500).send(utils.inputErrors("").global)
        }
    }

    // to verify the email adress
    async verifyEmail(req, res) {
        try {
            let account = res.locals.account

            const expireTime = account.email_expiredtime - Math.floor(Date.now() / 1000)
            if (expireTime <= 0) {
                return res.status(400).json(utils.inputErrors('token').token_expired)
            }

            if (req.body.verified_digits === account.email_verified_digits) {
                account.email_verified = 1

                account.save()
                return res.status(202).send({ msg: 'email verified succesfully' })
            }
            else {
                return res.status(400).json(utils.inputErrors('token').invalid_format)
            }
        } catch (e) {
            return res.status(500).send(utils.inputErrors("").global)
        }
    }

    // to generate a new email verified number
    async generateEmailDigits(req, res) {

        try {
            let account = res.locals.account

            if (account.email_verified === 1) {
                return res.status(403).send({ msg: 'email already verified' })
            }


            account.email_verified_digits = Math.floor(Math.random() * 999999 + 100000)
            account.email_expiredtime = Math.floor(Date.now() / 1000) + 600
            await account.save()
            
            //email part

            return res.status(202).send({ msg: 'email token generate successfully' })

        } catch (e) {
            return res.status(500).send(utils.inputErrors("").global)
        }
    }


    // to generate a new phone verified number
    async generatePhoneDigits(req, res) {

        try {
            let account = res.locals.account

            if (account.phone_verified === 1) {
                return res.status(403).send({ msg: 'phone already verified' })
            }


            account.phone_verified_digits = utils.generateDigits()
            account.phone_expiredtime = utils.generateExpiredTime()
            await account.save()
            return res.status(202).send({ msg: 'phone token generate successfully' })

        } catch (e) {
            return res.status(500).send(utils.inputErrors("").global)
        }

    }


    // to update the email adress
    async updateEmail(req, res) {
        try {

            let account = res.locals.account
            account.email = req.body.email
            account.email_verified_digits = utils.generateDigits()
            account.email_expiredtime = utils.generateExpiredTime()
            account.email_verified = 0
            // update account status
            account.status = 0

            await account.save()

            // email part

            return res.status(202).send({ msg: \"email changed successfully\" })

        } catch (error) {
            return res.status(500).send(utils.inputErrors('').global)
        }


    }


    // to update the phone number
    async updatePhone(req, res) {
        try {
            let account = res.locals.account
            account.phone = req.body.phone
            account.phone_verified_digits = utils.generateDigits()
            account.phone_expiredtime = utils.generateExpiredTime()
            account.phone_verified = 0
            // update account status
            account.status = 0
            await account.save()


            return res.sendStatus(202)

        } catch (e) {
            return res.status(500).send(utils.inputErrors('').global)
        }

    }


    // to update the password
    async updatePassword(req, res) {
        try {

            let account = res.locals.account

            if (!req.body.current_password) {
                return res.status(400).send({ msg: 'current password is required' })
            }

            if (!req.body.password) {
                return res.status(400).send({ msg: 'new password is required' })
            }


            if (req.body.password.trim().length < 8) {
                return res.status(400).send({ errors: [utils.inputErrors('password').incorrect_length] })
            }

            const currentPassword = config.crypto.pbkdf2Sync(req.body.current_password, 'salt', 1, 32, 'sha512').toString('hex')

            if (currentPassword !== account.password) {
                return res.status(400).send({ errors: [utils.inputErrors('current_password').incorrect_value] })
            }


            account.password = config.crypto.pbkdf2Sync(req.body.password, 'salt', 1, 32, 'sha512').toString('hex')
            await account.save()
            return res.status(202).send({ msg: 'password modified successfully' })

        } catch (err) {
            return res.status(500).send({ msg: 'unknow error' })
        }
    }

} module.exports = new $controllerClass($1Service)" > $1"-controller.js"
else
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
    " >$1"-controller.js"
fi

#routes
cd ../routes
mkdir -p -- $1
cd $1
touch $1".js"
touch middlewares.js

if [ $1 == "account" ] && [ $2 == "--default" ]; then
echo "const utils = require('../../utils/functions')

exports.getAccount = (account) => {
    return async (req, res, next) => {
        let account_ = await account.findByPk(res.locals.id)
        if(!account_){
          return res.status(404).send(utils.inputErrors('').account_not_found)
        }
        res.locals.account = account_
        next()
    }
}

exports.hasPhoneVerified = () => {
  return async (req, res, next) => {
      let account = res.locals.account
      
      if(account.phone_verified){
        return res.status(403).send(utils.inputErrors('').access_denied)
      }
      next()
  }
}

exports.hasEmailVerified = () => {
  return async (req, res, next) => {
      let account = res.locals.account
      
      if(account.email_verified){
        return res.status(403).send(utils.inputErrors('').access_denied)
      }
      next()
  }
}" > "middlewares.js"
fi

if [ $1 == "account" ] && [ $2 == "--default" ]; then
echo "const config = require('../../config')
const AccountController = require(config['controllers']+'/account-controller')
const tokenblacklist = require(config['models']+'/tokenblacklist')
const expressRouter = config.express.Router()
const bodyParser = require('body-parser');
const jsonParser = bodyParser.json()
const account = require(config.models+'/account')
const globalMiddlewares = require('../middlewares')
const accountMiddlewares = require('./middlewares')


expressRouter.post('/create', jsonParser, AccountController.insert)
expressRouter.delete('/delete',jsonParser, AccountController.delete)
expressRouter.post('/login',jsonParser, AccountController.login)



expressRouter.post(
    '/logout',
    jsonParser, 
    globalMiddlewares.verifyToken(config.jwt, tokenblacklist),
    accountMiddlewares.getAccount(account),
    AccountController.logout
)


expressRouter.put(
    '/update/verify/phone',
    jsonParser,
    globalMiddlewares.verifyToken(config.jwt, tokenblacklist),
    accountMiddlewares.getAccount(account),
    accountMiddlewares.hasPhoneVerified(),
    AccountController.verifyPhone
)

expressRouter.put(
    '/update/verify/email', 
    jsonParser,
    globalMiddlewares.verifyToken(config.jwt, tokenblacklist),
    accountMiddlewares.getAccount(account),
    accountMiddlewares.hasEmailVerified(),
    AccountController.verifyEmail
)

expressRouter.put(
    '/update/generatetoken/email', 
    globalMiddlewares.verifyToken(config.jwt, tokenblacklist),
    accountMiddlewares.getAccount(account),
    accountMiddlewares.hasEmailVerified(),
    AccountController.generateEmailDigits
)

expressRouter.put(
    '/update/generatetoken/phone', 
    globalMiddlewares.verifyToken(config.jwt, tokenblacklist),
    accountMiddlewares.getAccount(account),
    accountMiddlewares.hasPhoneVerified(),
    AccountController.generatePhoneDigits
)


expressRouter.put(
    '/update/phone', 
    jsonParser,
    globalMiddlewares.verifyToken(config.jwt, tokenblacklist),
    accountMiddlewares.getAccount(account),
    AccountController.updatePhone
)

expressRouter.put(
    '/update/email', 
    jsonParser,
    globalMiddlewares.verifyToken(config.jwt, tokenblacklist),
    accountMiddlewares.getAccount(account),
    AccountController.updateEmail
)

expressRouter.put(
    '/update/password',
    jsonParser, 
    globalMiddlewares.verifyToken(config.jwt, tokenblacklist),
    accountMiddlewares.getAccount(account),
    AccountController.updatePassword
)

module.exports = expressRouter" >$1".js"

else
echo "const config = require('../../config')
const $controllerClass = require(config['controllers']+'/$1-controller')
const expressRouter = config.express.Router()
const bodyParser = require('body-parser');
const jsonParser = bodyParser.json()
//const globalMiddlewares = require('../middlewares')

expressRouter.post('/create', jsonParser, $controllerClass.insert)
expressRouter.get('/', $controllerClass.getAll)
expressRouter.put('/update',jsonParser,$controllerClass.update)
expressRouter.delete('/delete',jsonParser, $controllerClass.delete)


module.exports = expressRouter" >$1".js"
fi

#index.js
#add the route to the index
cd ../..
node router.js $1
node migration.js $1

if [ $1 == "account" ] && [ $2 == "--default" ]; then
node migration.js tokenblacklist
fi