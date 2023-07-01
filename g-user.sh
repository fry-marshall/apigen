#!/bin/bash

cd src/app/models
touch "user.ts"


echo "import { DataTypes, Model } from \"sequelize\";
import sequelize from \"../../config/database\";

interface UserAttributes{
    id?: string;
    phone?: string;
    phone_verified_digits?: string;
    phone_expiredtime?: string;
    phone_verified?: boolean;
    email?: string;
    email_verified_digits?: string;
    email_expiredtime?: string;
    email_verified?: boolean;
    password?: string;
    status?: boolean;
}

interface UserInstance extends Model<UserAttributes>, UserAttributes{}

const User = sequelize.define<UserInstance>('user', {
    id: {
        type: DataTypes.STRING,
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
})

export default User;" > "user.ts"




echo "import { DataTypes, Model } from \"sequelize\";
import sequelize from \"../../config/database\";

interface TokenBlackListAttributes{
    id?: string;
    token?: string;
}

interface TokenBlackListInstance extends Model<TokenBlackListAttributes>, TokenBlackListAttributes{}

const TokenBlackList = sequelize.define<TokenBlackListInstance>('tokenblacklist', {
    id: {
        type: DataTypes.STRING,
        primaryKey: true
    },
    token: {
        type: db.DataTypes.STRING,
        allowNull: false,
        unique: true,
    }, 
})

export default TokenBlackList;" > "tokenblacklist.ts"


cd ..


#services
cd services
touch user-service.ts
echo "
import { ModelStatic } from \"sequelize\";
import Service from \"./service\";

    
class UserService extends Service {
    
    constructor(model: ModelStatic<any>) {
        super(model)
    }
}

export default UserService" >"user-service.ts"


touch tokenblacklist-service.ts
echo "
import { ModelStatic } from \"sequelize\";
import Service from \"./service\";

    
class TokenBlackListService extends Service {
    
    constructor(model: ModelStatic<any>) {
        super(model)
    }
}

export default TokenBlackListService" >"tokenblacklist-service.ts"



cd ..



#controllers
cd controllers
touch "user-controller.js"

echo "
import Service from \"../services/service\";
import Express from "express";
import { defaultApiErrorValue } from "../models/interfaces/errors";
import UserService from \"../services/user-service\";
import Controller from \"./controller\";
import User from \"../models/user\";
import TokenBlackList from "../models/tokenblacklist";
import TokenBlackList from \"../models/tokenblacklist\";
import jwt from \"jsonwebtoken\"
import bcrypt from \"bcrypt\";
import { v4 as uuidv4 } from \"uuid\";

  
class UserController extends Controller {
  
    constructor(service) {
        super(service);
    }  


    // to create an account
    async insert(req: Express.Request, res: Express.Response) {

        try {
            req.body.identifier = config.uuid.v4()
            const passwordError = utils.validPassword(req.body.password)
            if (req.body.password.length < 8) {
                const validationErrors = { error: { name: 'incorrect_length', status: 400, fields: [ {status: 8, name: 'password} ] }}
                return res.status(400).send({is_error: true, value: validationErrors})
            }

            const body = {
                id: uuidv4(),
                email: req.body?.email,
                email_verified_digits: Math.floor(Math.random() * 999999 + 100000),
                email_expiredtime: Math.floor(Date.now() / 1000) + 600
                phone: req.body?.phone,
                phone_verified_digits: Math.floor(Math.random() * 999999 + 100000),
                phone_expiredtime: Math.floor(Date.now() / 1000) + 600
            }

            let response = await this.service.insert(body)

            if ( response?.is_error ){
                return res.status(400).send(response);
            }

            const validReponse = {is_error: false, value: {status: 201, data: 'item created successfully'} }
            return res.status(201).send(validReponse)

        } catch (e) {
            return res.status(500).send({is_error: true, value: defaultApiErrorValue})
        }

    }

 

    // to log in an account
    async logIn(req: Express.Request, res: Express.Response) {
        try {

            let currentUser = await User.findOne({
                where: {
                    login: req.body.login,
                }
            })

            if(!currentUser){
                const validationErrors = { error: { name: 'not_found', status: 404, message: 'Item not found' }}
                return res.status(404).send({is_error: true, value: validationErrors} as ResponseRequest)
            }

            const passwordIsGood = bcrypt.compareSync(req.body.password, currentUser.password!);

            if(!passwordIsGood){
                const validationErrors = { error: { name: 'not_found', status: 404, message: 'Item not found' }}
                return res.status(404).send({is_error: true, value: validationErrors} as ResponseRequest)
            }

            const access_token = jwt.sign({ id: currentUser.id }, process.env.ACCESS_TOKEN_SECRET!, {expiresIn: '1h'})
            const refresh_token = jwt.sign({ id: currentUser.id }, process.env.ACCESS_TOKEN_SECRET!, {expiresIn: '30d'})

            const validReponse = {is_error: false, value: {status: 200, data: {access_token, refresh_token}} }
            return res.status(200).send(validReponse)

        }catch(error){
            return res.status(500).send({is_error: true, value: defaultApiErrorValue})
        }
    }

    // to log out an account
    async logOut(req: Express.Request, res: Express.Response) {

        try {
            const token = res.locals.token

            let tokenBlackListCreated = await TokenBlackList.create({
                id: uuidv4(),
                token
            })

            const validReponse = {is_error: false, value: {status: 200, data: 'user logout successfully'} }
            return res.status(200).send(validReponse)

        }catch(error){
            return res.status(500).send({is_error: true, value: defaultApiErrorValue})
        }
    }


    // to verify the phone number
    async verifyPhone(req: Express.Request, res: Express.Response) {

        try {
            let user = res.locals.user

            const expireTime = user.phone_expiredtime - Math.floor(Date.now() / 1000)
            if (expireTime <= 0) {
                const validationErrors = { error: { name: 'expired', status: 400, message: 'Expired verification code' }}
                return res.status(400).send({is_error: true, value: validationErrors} as ResponseRequest)
            }

            if (req.body.verified_digits === user.phone_verified_digits) {
                user.phone_verified = 1

                await user.save()
                const validReponse = {is_error: false, value: {status: 200, data: 'phone verified successfully'} }
                return res.status(202).send(validReponse)
            }
            else {
                const validationErrors = { error: { name: 'invalid', status: 400, message: 'Invalid verification code' }}
                return res.status(404).send({is_error: true, value: validationErrors} as ResponseRequest)
            }

        }catch(error){
            return res.status(500).send({is_error: true, value: defaultApiErrorValue})
        }
    }

    // to verify the email adress
    async verifyEmail(req: Express.Request, res: Express.Response) {
        try {
            let user = res.locals.user

            const expireTime = user.email_expiredtime - Math.floor(Date.now() / 1000)
            if (expireTime <= 0) {
                const validationErrors = { error: { name: 'expired', status: 400, message: 'Expired verification code' }}
                return res.status(400).send({is_error: true, value: validationErrors} as ResponseRequest)
            }

            if (req.body.verified_digits === user.email_verified_digits) {
                user.email_verified = 1

                await user.save()
                const validReponse = {is_error: false, value: {status: 200, data: 'email verified successfully'} }
                return res.status(202).send(validReponse)
            }
            else {
                const validationErrors = { error: { name: 'invalid', status: 400, message: 'Invalid verification code' }}
                return res.status(404).send({is_error: true, value: validationErrors} as ResponseRequest)
            }

        }catch(error){
            return res.status(500).send({is_error: true, value: defaultApiErrorValue})
        }
    }

    // to generate a new email verified number
    async generateEmailDigits(req: Express.Request, res: Express.Response) {

        try {
            let user = res.locals.user

            if (user.email_verified === 1) {
                const validationErrors = { error: { name: 'verified', status: 400, message: 'Email already verified' }}
                return res.status(400).send({is_error: true, value: validationErrors} as ResponseRequest)
            }

            user.email_verified_digits = Math.floor(Math.random() * 999999 + 100000)
            user.email_expiredtime = Math.floor(Date.now() / 1000) + 600
            await user.save()
            
            //email part

            const validReponse = {is_error: false, value: {status: 200, data: 'Email verification code generated successfully'} }
            return res.status(202).send(validReponse)

        }catch(error){
            return res.status(500).send({is_error: true, value: defaultApiErrorValue})
        }
    }


    // to generate a new phone verified number
    async generatePhoneDigits(req: Express.Request, res: Express.Response) {

         try {
            let user = res.locals.user

            if (user.phone_verified === 1) {
                const validationErrors = { error: { name: 'verified', status: 400, message: 'Phone already verified' }}
                return res.status(400).send({is_error: true, value: validationErrors} as ResponseRequest)
            }

            user.phone_verified_digits = Math.floor(Math.random() * 999999 + 100000)
            user.phone_expiredtime = Math.floor(Date.now() / 1000) + 600
            await user.save()
            
            //phone part

            const validReponse = {is_error: false, value: {status: 200, data: 'Phone verification code generated successfully'} }
            return res.status(202).send(validReponse)

        }catch(error){
            return res.status(500).send({is_error: true, value: defaultApiErrorValue})
        }
    }


    // to update the email adress
    async updateEmail(req: Express.Request, res: Express.Response) {
        try {

            let user = res.locals.user
            user.email = req.body.email
            user.email_verified_digits = Math.floor(Math.random() * 999999 + 100000)
            user.email_expiredtime = Math.floor(Date.now() / 1000) + 600
            user.email_verified = 0
            // update user status
            user.status = 0

            await user.save()

            // email part

            const validReponse = {is_error: false, value: {status: 200, data: 'Email updated successfully'} }
            return res.status(202).send(validReponse)

        }catch(error){
            return res.status(500).send({is_error: true, value: defaultApiErrorValue})
        }
    }


    // to update the phone number
    async updatePhone(req: Express.Request, res: Express.Response) {
        try {
            let user = res.locals.user
            user.phone = req.body.phone
            user.phone_verified_digits = Math.floor(Math.random() * 999999 + 100000)
            user.phone_expiredtime = Math.floor(Date.now() / 1000) + 600
            user.phone_verified = 0
            // update user status
            user.status = 0

            await user.save()

            // phone part

            const validReponse = {is_error: false, value: {status: 200, data: 'Phone updated successfully'} }
            return res.status(202).send(validReponse)

        } catch(error){
            return res.status(500).send({is_error: true, value: defaultApiErrorValue})
        }

    }


    // to update the password
    async updatePassword(req: Express.Request, res: Express.Response) {
        try {

            let user = res.locals.user

            if (!req.body.current_password) {
                const validationErrors = { error: { name: 'verified', status: 400, fields: [{name: 'current_password', status: 1}]  }}
                return res.status(400).send(validationErrors)
            }

            if (!req.body.password) {
                const validationErrors = { error: { name: 'verified', status: 400, fields: [{name: 'password', status: 1}]  }}
                return res.status(400).send(validationErrors)
            }


            if (req.body.password.trim().length < 8) {
                const validationErrors = { error: { name: 'verified', status: 400, fields: [{name: 'password', status: 8}]  }}
                return res.status(400).send(validationErrors)
                return res.status(400).send({ errors: [utils.inputErrors('password').incorrect_length] })
            }

            const passwordIsGood = bcrypt.compareSync(req.body.current_password, user.password!);

            if (passwordIsGood) {
                const validationErrors = { error: { name: 'incorrect_value', status: 400, fields: [ {name: 'current_password', status: 3} ]}}
                return res.status(400).send({is_error: true, value: validationErrors} as ResponseRequest)
            }

            user.password = bcrypt.hashSync(req.body.password, 10)
            await account.save()
            const validReponse = {is_error: false, value: {status: 200, data: 'Password updated successfully'} }
            return res.status(202).send(validReponse)

        } catch(error){
            return res.status(500).send({is_error: true, value: defaultApiErrorValue})
        }
    }

    
    async refreshToken(req: Express.Request, res: Express.Response) {
        try {
            const authHeader = req.headers['authorization']
            const refreshtoken = authHeader && authHeader.split(' ')[1]

            jwt.verify(refreshtoken!, process.env.REFRESH_TOKEN_SECRET!, async (err, user: any) => {

                const token = await TokenBlackList.findOne({
                    where: {
                        token: refreshtoken
                    }
                })

                if (err || token) {
                    const validationErrors = { error: { name: 'invalid_refresh_token', status: 401, message: 'Invalid refresh token' } }
                    return res.status(401).send({ is_error: true, value: validationErrors } as ResponseRequest)
                } else {
                    const access_token = jwt.sign({ id: user.id }, process.env.ACCESS_TOKEN_SECRET!, { expiresIn: '1h' })
                    const refresh_token = jwt.sign({ id: user.id }, process.env.REFRESH_TOKEN_SECRET!, { expiresIn: '30d' })

                    return res.status(200).send({ access_token, refresh_token })
                }
            })

        } catch (error) {
            return res.status(500).send({ is_error: true, value: defaultApiErrorValue })
        }
    }
} 

export default new UserController(new UserService(User));" > "user-controller.js"


touch tokenblacklist-controller.ts
echo "
import Service from \"../services/service\";
import TokenBlackListService from \"../services/tokenblacklist-service\";
import Controller from \"./controller\";
import TokenBlackList from \"../models/tokenblacklist\";

    
class TokenBlackListController extends Controller {
    
    constructor(service: Service) {
        super(service);
    }
}
export default new TokenBlackListController(new TokenBlackListService(TokenBlackList));" > "tokenblacklist-controller.ts"


cd ..


#routes
cd routes
mkdir -p -- user
cd user
touch "user.ts"
touch middlewares.ts


echo "
import Express from \"express\"
import UserController from \"../../controllers/user-controller\"
import userMiddlewares from \"./middlewares\"
import globalMiddlewares from \"../middlewares\"

const router = Express.Router()


router.post('/create', Express.json(), UserController.insert)
router.delete('/delete',Express.json(), UserController.delete)
router.post('/login',Express.json(), UserController.logIn)

router.post(
    '/logout',
    Express.json(), 
    globalMiddlewares.verifyToken(),
    userMiddlewares.getUser(),
    UserController.logOut
)

router.put(
    '/update/verify/phone',
    Express.json(),
    globalMiddlewares.verifyToken(),
    userMiddlewares.getUser(),
    userMiddlewares.hasPhoneVerified(),
    UserController.verifyPhone
)

router.put(
    '/update/verify/email', 
    Express.json(),
    globalMiddlewares.verifyToken(),
    userMiddlewares.getUser(),
    userMiddlewares.hasEmailVerified(),
    UserController.verifyEmail
)

router.put(
    '/update/generatetoken/email', 
    globalMiddlewares.verifyToken(),
    userMiddlewares.getUser(),
    userMiddlewares.hasEmailVerified(),
    UserController.generateEmailDigits
)

router.put(
    '/update/generatetoken/phone', 
    globalMiddlewares.verifyToken(),
    userMiddlewares.getUser(),
    userMiddlewares.hasPhoneVerified(),
    UserController.generatePhoneDigits
)

router.put(
    '/update/phone', 
    Express.json(),
    globalMiddlewares.verifyToken(),
    userMiddlewares.getUser(),
    UserController.updatePhone
)

router.put(
    '/update/email', 
    Express.json(),
    globalMiddlewares.verifyToken(),
    userMiddlewares.getUser(),
    UserController.updateEmail
)

router.put(
    '/update/password',
    Express.json(), 
    globalMiddlewares.verifyToken(),
    userMiddlewares.getUser(),
    UserController.updatePassword
)

export default router" > "user.ts"


echo "
import {Request, Response, NextFunction} from \"express\";
import User from \"../../models/user\"; 

exports.getUser = (user: User) => {
    return async (req: Request, res: Response, next: NextFunction) => {
        let currentUser = await user.findByPk(res.locals.id)
        if(!currentUser){
            const validationErrors = { error: { name: 'not_found', status: 404, message: 'Item not found' }}
            return res.status(404).send({is_error: true, value: validationErrors})
        }
        res.locals.user = currentUser
        next()
    }
}

exports.hasPhoneVerified = () => {
  return async (req: Request, res: Response, next: NextFunction) => {
      let currentUser = res.locals.user
      
      if(currentUser.phone_verified){
        const validationErrors = { error: { name: 'access_denied', status: 403, message: 'Phone not verified' }}
        return res.status(403).send({is_error: true, value: validationErrors})
      }
      next()
  }
}

exports.hasEmailVerified = () => {
  return async (req: Request, res: Response, next: NextFunction) => {
      let currentUser = res.locals.user
      
      if(currentUser.email_verified){
        const validationErrors = { error: { name: 'access_denied', status: 403, message: 'Email not verified' }}
        return res.status(403).send({is_error: true, value: validationErrors})
      }
      next()
  }
}" > "middlewares.ts"


cd ..
#add router
routerFile="router.ts"
importModel="import UserRouter from \"./user/user\""
importRouter="app.use(\"/user\", UserRouterRouter)"
import_model_line=1
import_router_line=$(grep -n "app.use(express." "$routerFile" | cut -d ":" -f 1)
import_router_line=$import_router_line+2

if [ -n "$import_router_line" ]; then
    printf "%s\n" "${import_model_line}i" "$importModel" . w | ed -s "$routerFile"
    printf "%s\n" "${import_router_line}i" "$(printf '\t')$importRouter" . w | ed -s "$routerFile"
fi


cd ../..
cd config
#config
configFile='migrations.ts'
import_model_user_line=1
import_model_token_line=2
importModelUser="import User from \"../app/models/user\"";
importModelToken="import TokenBlackList from \"../app/models/tokenblacklist\"";
importConfigUser="await User.sync({ alter: true });"
importConfigToken="await TokenBlackList.sync({ alter: true });"
import_migration_line=$(grep -n "})();" "$configFile" | cut -d ":" -f 1)
import_migration_token_line=$import_migration_line+2

if [ -n "$import_migration_line" ]; then
    printf "%s\n" "${import_model_user_line}i" "$importModelUser" . w | ed -s "$configFile"
    printf "%s\n" "${import_migration_line}i" "$(printf '\t')$importConfigUser" . w | ed -s "$configFile"
fi

if [ -n "$import_migration_token_line" ]; then
    printf "%s\n" "${import_model_token_line}i" "$importModelToken" . w | ed -s "$configFile"
    printf "%s\n" "${import_model_token_line}i" "$(printf '\t')$importConfigToken" . w | ed -s "$configFile"
fi