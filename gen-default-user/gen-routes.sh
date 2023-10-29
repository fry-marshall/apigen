#!/bin/bash

#generate routes
cd routes

mkdir -p -- user
cd user
touch user.ts
echo "import Express from \"express\"
import UserController from \"../../controllers/user-controller\"
import * as userMiddlewares from \"./middlewares\"
import GlobalMiddlewares from \"../global-middlewares\"

const router = Express.Router()


router.post('/create', Express.json(), UserController.insert)
router.post('/login',Express.json(), UserController.logIn)
router.post('/refreshtoken',Express.json(), UserController.refreshToken)

router.post(
    '/logout',
    Express.json(), 
    GlobalMiddlewares.verifyToken,
    userMiddlewares.getUser,
    UserController.logOut
)

router.put(
    '/update/generatetoken/email',
    Express.json(), 
    GlobalMiddlewares.verifyToken,
    userMiddlewares.getUser,
    UserController.generateEmailToken
)
router.put(
    '/update/generatetoken/phone',
    Express.json(), 
    GlobalMiddlewares.verifyToken,
    userMiddlewares.getUser,
    UserController.generatePhoneDigits
)

router.put(
    '/update/verify/phone',
    Express.json(), 
    GlobalMiddlewares.verifyToken,
    userMiddlewares.getUser,
    UserController.verifyPhone
)

router.put(
    '/update/verify/email',
    Express.json(),
    UserController.verifyEmail
)

router.put('/update/forgotpassword',Express.json(), UserController.forgotPassword)
router.put('/update/forgotpassword/change',Express.json(), UserController.changeForgotPassword)

router.put(
    '/update',
    Express.json(), 
    GlobalMiddlewares.verifyToken,
    userMiddlewares.getUser,
    UserController.update
)

router.delete(
    '/delete',
    Express.json(), 
    GlobalMiddlewares.verifyToken,
    userMiddlewares.getUser,
    UserController.delete
)

export default router" > user.ts

#user middleware
touch middlewares.ts
echo "import {Request, Response, NextFunction} from \"express\";
import { User } from \"../../models/user\";

const getUser = async (req: Request, res: Response, next: NextFunction) => {
  let currentUser = await User.findByPk(res.locals.id)
  if (!currentUser) {
    const validationErrors = { error: { name: 'not_found', status: 404, message: 'Item not found' } }
    return res.status(404).send({ is_error: true, value: validationErrors })
  }
  res.locals.user = currentUser
  next()
}

const hasPhoneVerified = (req: Request, res: Response, next: NextFunction) => {
  let currentUser = res.locals.user

  if (currentUser.phone_verified) {
    const validationErrors = { error: { name: 'access_denied', status: 403, message: 'Phone not verified' } }
    return res.status(403).send({ is_error: true, value: validationErrors })
  }
  next()
}

const hasEmailVerified = (req: Request, res: Response, next: NextFunction) => {
  let currentUser = res.locals.user

  if (currentUser.email_verified) {
    const validationErrors = { error: { name: 'access_denied', status: 403, message: 'Email not verified' } }
    return res.status(403).send({ is_error: true, value: validationErrors })
  }
  next()
}

export { hasEmailVerified, hasPhoneVerified, getUser }" > middlewares.ts

cd ..

#add router
routerFile="router.ts"
importModel="import UserRouter from \"./user/user\""
importRouter="app.use(\"/user\", UserRouter)"
import_model_line=1
import_router_line=$(grep -n "(app: Express) => {" "$routerFile" | cut -d ":" -f 1)
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
importModelUser="import { User } from \"../app/models/user\"";
importModelToken="import { TokenBlackList } from \"../app/models/tokenblacklist\"";
importConfigUser="await User.sync({ alter: true });"
importConfigToken="await TokenBlackList.sync({ alter: true });"
import_migration_line=$(grep -n "})();" "$configFile" | cut -d ":" -f 1)+1
import_migration_token_line=$import_migration_line+2

if [ -n "$import_migration_line" ]; then
    printf "%s\n" "${import_model_user_line}i" "$importModelUser" . w | ed -s "$configFile"
    printf "%s\n" "${import_migration_line}i" "$(printf '\t')$importConfigUser" . w | ed -s "$configFile"
fi

if [ -n "$import_migration_token_line" ]; then
    printf "%s\n" "${import_model_token_line}i" "$importModelToken" . w | ed -s "$configFile"
    printf "%s\n" "${import_migration_token_line}i" "$(printf '\t')$importConfigToken" . w | ed -s "$configFile"
fi

cd ..