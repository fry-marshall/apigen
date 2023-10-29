#!/bin/bash

#generate controllers
cd controllers

touch user-controller.ts
echo "import Controller from \"./controller\";
import { Request, Response } from \"express\"
import bcrypt from \"bcrypt\";
import jwt from \"jsonwebtoken\"
import { v4 as uuidv4 } from \"uuid\";
import Service from \"../services/service\";
import UserService from \"../services/user-service\";
import { User, UserAttributes, UserInstance } from \"../models/user\";
import Helpers from \"../../helpers/helpers\";
import { TokenBlackList } from \"../models/tokenblacklist\";

class UserController extends Controller {
  
    constructor(service: Service) {
        super(service);
    }  

    // to create an account
    async insert(req: Request, res: Response) {
        try {
            if (req.body.password && req.body.password.length < 8) {
                const error = { msg: 'fields errors', fields: [ {status: 'len', name: 'password'} ] }
                return res.status(400).json(Helpers.queryError(error))
            }
            const body: Partial<UserAttributes> = {
                id: uuidv4(),
                email: req.body?.email,
                email_verified_token: uuidv4(),
                email_expiredtime: Helpers.timeAfterSecond(600).toString(),
                indicative: req.body?.indicative,
                phone: req.body?.phone,
                phone_verified_digits: Math.floor(Math.random() * 999999 + 100000).toString(),
                phone_expiredtime: Helpers.timeAfterSecond(600).toString(),
                password: req.body?.password,
                account_type: req.body?.account_type,
            }

            const response = await this.service.insert(body)

            if (response.is_error){
                return res.status(400).send(response);
            }

            // send the verification email
            const url = 'http://localhost:3000/user/update/verify/email?token='+(response as any).data.email_verified_token
            await Helpers.mailTransporter.sendMail({
                from: process.env.MAIL_USERNAME,
                to: body.email,
                subject: 'Vérification de l\'adresse mail',
                html: Helpers.verifyEmail(body.email!, url),
            })

            // send the verification phone number
            Helpers.smsTransporter.messages.create({
                body: 'Votre code de vérification est ' + (response as any).data.phone_verified_token + ' ( valable pendant 10 minutes )',
                from: process.env.TWILIO_NUMBER,
                to: body.phone!
            })
            .then(console.log)
            .catch(console.log)

            return res.status(201).json(Helpers.queryResponse({id: (response as any).data.id, msg: 'User account created successfully'}))

        } catch (e) {
            return res.status(500).json(Helpers.serverError)
        }
    }

    // to log in an account
    async logIn(req: Request, res: Response) {
        try {

            let isError = false;
            let fieldsErrors = []

            if(!req.body.login){
                isError = true;
                fieldsErrors.push({
                    name: 'login',
                    status: 'is_null'
                })
            }

            if(!req.body.password){
                isError = true;
                fieldsErrors.push({
                    name: 'password',
                    status: 'is_null'
                })
            }

            if(isError){
                return res.status(400).json(Helpers.queryError({msg: 'fields errors', fields: fieldsErrors}))
            }

            let currentUser = await User.findOne({
                where: {
                    email: req.body.login,
                }
            })

            if(!currentUser){
                return res.status(404).json(Helpers.notFoundError)
            }

            const passwordIsGood = bcrypt.compareSync(req.body.password, currentUser.password!);
            if(!passwordIsGood){
                return res.status(404).json(Helpers.notFoundError)
            }

            const access_token = jwt.sign({ id: currentUser.id }, process.env.ACCESS_TOKEN_SECRET!, {expiresIn: '1h'})
            const refresh_token = jwt.sign({ id: currentUser.id }, process.env.REFRESH_TOKEN_SECRET!, {expiresIn: '7d'})

            return res.status(200).json(Helpers.queryResponse({access_token, refresh_token}))

        }catch(error){
            return res.status(500).json(Helpers.serverError)
        }
    }

    // to log out an account
    async logOut(req: Request, res: Response) {

        try {
            const token = res.locals.token
            await TokenBlackList.create({id: uuidv4(),token})
            return res.status(200).json(Helpers.queryResponse('user logout successfully'))
        }catch(error){
            return res.status(500).json(Helpers.serverError)
        }
    }

    // to verify the phone number
    async verifyPhone(req: Request, res: Response) {
        try {
            let user = res.locals.user

            if(user.phone_verified){
                return res.status(400).json(Helpers.queryError({status: 'verified', msg: 'Phone already verified'}))
            }

            const expireTime = user.phone_expiredtime - Math.floor(Date.now() / 1000)
            if (expireTime <= 0) {
                return res.status(400).json(Helpers.queryError({status: 'expired', msg: 'Expired verification code'}))
            }

            if (req.body.verified_digits === user.phone_verified_digits) {
                user.phone_verified = true
                await user.save()
                return res.status(202).json(Helpers.queryResponse('phone verified successfully'))
            }
            else {
                return res.status(400).json(Helpers.queryError({status: 'incorrect', msg: 'Incorrect verification code'}))
            }
        }catch(error){
            return res.status(500).json(Helpers.serverError)
        }
    }

    // to verify the email adress
    async verifyEmail(req: Request, res: Response) {
        try {
            const token = req.query.token

            if(!token){
                return res.status(400).json(Helpers.queryError({msg: 'token argument is missing'})) 
            }

            const user = await User.findOne({
                where: {
                    email_verified_token: token as string
                }
            })

            if(!user){
                return res.status(404).json(Helpers.notFoundError)
            }

            if(user.email_verified){
                return res.status(400).json(Helpers.queryError({status: 'verified', msg: 'Email already verified'}))
            }

            const expireTime = parseInt(user.email_expiredtime) - Math.floor(Date.now() / 1000)
            if (expireTime <= 0) {
                return res.status(400).json(Helpers.queryError({status: 'expired', msg: 'Expired verification code'}))
            }

            user.email_verified = true
            await user.save()
            return res.status(202).json(Helpers.queryResponse('email verified successfully'))

        }catch(error){
            return res.status(500).json(Helpers.serverError)
        }
    }

    // to generate a new email verified number
    async generateEmailToken(req: Request, res: Response) {
        try {
            let user = res.locals.user
            if (user.email_verified) {
                return res.status(400).json(Helpers.queryError({status: 'verified', msg: 'Email already verified'}))
            }

            user.email_verified_token = uuidv4()
            user.email_expiredtime = Math.floor(Date.now() / 1000) + 600
            await user.save()
            
            const url = 'http://localhost:3000/user/update/verify/email?token='+user.email_verified_token
            await Helpers.mailTransporter.sendMail({
                from: process.env.MAIL_USERNAME,
                to: user.email,
                subject: 'Vérification de l\'adresse mail',
                html: Helpers.verifyEmail(user.email, url),
            });

            return res.status(202).json(Helpers.queryResponse('Email verification code generated successfully'))
        }catch(error){
            return res.status(500).json(Helpers.serverError)
        }
    }

    // to generate a new phone verified number
    async generatePhoneDigits(req: Request, res: Response) {

         try {
            let user = res.locals.user

            if (user.phone_verified) {
                return res.status(400).json(Helpers.queryError({status: 'verified', msg: 'Phone already verified'}))
            }

            user.phone_verified_digits = Math.floor(Math.random() * 999999 + 100000)
            user.phone_expiredtime = Math.floor(Date.now() / 1000) + 600
            await user.save()
            
            Helpers.smsTransporter.messages.create({
                body: 'Votre code de vérification est ' + user.phone_verified_digits + ' ( valable pendant 10 minutes )',
                from: process.env.TWILIO_NUMBER,
                to: user.phone
            })
            .then(console.log)
            .catch(console.log)

            return res.status(202).json(Helpers.queryResponse('Phone verification code generated successfully'))

        }catch(error){
            return res.status(500).json(Helpers.serverError)
        }
    }

    // to update the user account        
    async update(req: Request, res: Response) {
        try {
            let user = res.locals.user as UserInstance
            let body: Partial<UserAttributes> = {
                firstname: req.body.firstname?.trim(),
                lastname: req.body.lastname?.trim(),
            }

            if (req.body.password) {
                const passwordIsGood = bcrypt.compareSync(req.body.current_password, user.password!);

                if (!passwordIsGood) {
                    const error = { msg: 'current password is incorrect', fields: [ {status: 'incorrect', name: 'current_password'} ] }
                    return res.status(400).json(Helpers.queryError(error))
                } else if(req.body.password.length < 8) {
                    const error = { msg: 'fields errors', fields: [ {status: 'len', name: 'password'} ] }
                    return res.status(400).json(Helpers.queryError(error))
                }else{
                    body.password = req.body.password
                }
            }

            if(req.body.phone){
                body.phone = req.body.phone
                body.phone_verified = false
                body.phone_expiredtime = Helpers.timeAfterSecond(600).toString()
                body.phone_verified_digits = Math.floor(Math.random() * 999999 + 100000).toString()
            }

            if(req.body.email){
                body.email = req.body.email
                body.email_verified = false
                body.email_expiredtime = Helpers.timeAfterSecond(600).toString()
                body.email_verified_token = uuidv4()
            }

            const response = await this.service.update(user.id, body)

            if (response.is_error){
                return res.status(400).send(response);
            }

            // send the verification email
            const url = 'http://localhost:3000/user/update/verify/email?token='+(response as any).data.email_verified_token
            await Helpers.mailTransporter.sendMail({
                from: process.env.MAIL_USERNAME,
                to: body.email,
                subject: 'Vérification de l\'adresse mail',
                html: Helpers.verifyEmail(body.email!, url),
            })

            // send the verification phone number
            Helpers.smsTransporter.messages.create({
                body: 'Votre code de vérification est ' + (response as any).data.phone_verified_token + ' ( valable pendant 10 minutes )',
                from: process.env.TWILIO_NUMBER,
                to: body.phone!
            })
            .then(console.log)
            .catch(console.log)

            return res.status(202).json(Helpers.queryResponse({id: user.id, msg: 'user account updated successfully'}))

        } catch (error) {
            return res.status(500).json(Helpers.serverError)
        } 
    }

    // to forgot the user account
    async forgotPassword(req: Request, res: Response) {
        try {
            const email = req.body.email

            if(!email){
                return res.status(400).json(Helpers.queryError({msg: 'email adress is missing'}))
            }
            
            let user = await User.findOne({
                where: {
                    email: req.body.email
                }
            })

            if (user) {
                user.forgotpasswordtoken = uuidv4()
                user.forgotpasswordused = false
                await user.save()
                
                const url = 'http://localhost:3000/forgotpassword/change?token='+user.forgotpasswordtoken

                await Helpers.mailTransporter.sendMail({
                    from: process.env.MAIL_USERNAME,
                    to: user.email,
                    subject: \"Mot de passe oublié\",
                    html: Helpers.resetPassword(user.email!, url),
                })
            }
            return res.status(202).json(Helpers.queryResponse('A reset password email sent successfully'))

        } catch (error) {
            return res.status(500).json(Helpers.serverError)
        }
    }

    // to change the user account password 
    async changeForgotPassword(req: Request, res: Response) {
        try {
            const token = req.query.token
            if(!token){
                return res.status(400).json(Helpers.queryError({msg: 'token argument is missing'}))
            }

            let user = await User.findOne({
                where: {
                    email: req.body.email,
                    forgotpasswordtoken: token as string,
                    forgotpasswordused: false
                }
            })

            if (!user) {
                return res.status(400).json(Helpers.queryError('Invalid token or email doesn\'t exist'))
            }

            if(req.body.password !== req.body.confirm_password){
                return res.status(400).json(Helpers.queryError('Password and confirmation password must be equals'))
            }

            if(req.body.password.length < 8){
                return res.status(400).json(Helpers.queryError({msg: 'fields errors', fields: [{name: 'password', status: 'len'}]}))
            }

            user.password = req.body.password
            user.forgotpasswordused = true;
            await user.save()

            return res.status(202).json(Helpers.queryResponse('password reset successfully'))

        } catch (error) {
            return res.status(500).json(Helpers.serverError)
        }
    }

    // to delete an account
    async delete(req: Request, res: Response) {
        try {
            let user = res.locals.user
            const id = user.id
            await user.destroy()

            return res.status(202).json(Helpers.queryResponse({id, msg: 'user account deleted successfully'}))

        } catch (error) {
            return res.status(500).json(Helpers.serverError)
        }
    }
    
    async refreshToken(req: Request, res: Response) {
        try {
            const authHeader = req.headers['authorization']
            const refreshtoken = (authHeader && authHeader.split(' ')[1]) || ''

            jwt.verify(refreshtoken!, process.env.REFRESH_TOKEN_SECRET!, async (err, user: any) => {

                const token = await TokenBlackList.findOne({
                    where: {
                        token: refreshtoken
                    }
                })
                if (err || token) {
                    return res.status(401).send(Helpers.invalidAccessTokenError)
                } else {
                    const access_token = jwt.sign({ id: user.id }, process.env.ACCESS_TOKEN_SECRET!, { expiresIn: '1h' })
                    const refresh_token = jwt.sign({ id: user.id }, process.env.REFRESH_TOKEN_SECRET!, { expiresIn: '7d' })
                    await TokenBlackList.create({id: uuidv4(), token: refreshtoken ?? ''})
                    return res.status(200).json(Helpers.queryResponse({ access_token, refresh_token }))
                }
            })

        } catch (error) {
            return res.status(500).json(Helpers.serverError)
        }
    }
} 

export default new UserController(new UserService(User));
" > user-controller.ts

#tokenblacklist controller
touch tokenblacklist-controller.ts
echo "import { TokenBlackList } from \"../models/tokenblacklist\";
import Service from \"../services/service\";
import TokenBlackListService from \"../services/tokenblacklist-service\";
import Controller from \"./controller\";

    
class TokenBlackListController extends Controller {
    
    constructor(service: Service) {
        super(service);
    }
}
export default new TokenBlackListController(new TokenBlackListService(TokenBlackList));" > tokenblacklist-controller.ts

cd ..