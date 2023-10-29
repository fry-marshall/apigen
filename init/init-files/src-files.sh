#!/bin/bash

cd src

#create the default src files
echo "create default src files ( controllers, services, etc...)"

#app.ts file
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

server.listen(process.env.PORT, () => {})

export default server" > app.ts

cd app

#controller file
cd controllers
touch controller.ts
echo "import Service from \"../services/service\";
import { Request, Response } from \"express\";

export default class Controller {

    protected service: Service

    constructor(service: Service) {
      this.service = service;
      this.getAll = this.getAll.bind(this);
      this.insert = this.insert.bind(this);
      this.update = this.update.bind(this);
      this.delete = this.delete.bind(this);
    }
  
    async getAll(req: Request, res: Response) {
        const response = await this.service.getAll()
        if(response.is_error){
            return res.status(500).json(response)
        }
        return res.status(200).json(response)
    }
  
    async insert(req: Request, res: Response) {
      const response = await this.service.insert(req.body);
      if (response.is_error){
        return res.status(400).json(response);
      }
      return res.status(201).json(response);
    }
  
    async update(req: Request, res: Response) {
      const { id } = req.body;
      const response = await this.service.update(id, req.body);
      if (response.is_error){
        return res.status(400).send(response);
      }
      return res.status(202).send(response);
    }
  
    async delete(req: Request, res: Response) {
      const { id } = req.body;
      const response = await this.service.delete(id);
      if (response.is_error){
        return res.status(500).send(response);
      }
      return res.status(202).send(response);
    }
  
}" > controller.ts

cd ..

#routes files
cd routes
touch router.ts
echo "import { Express} from \"express\"

const router = (app: Express) => {
}

export default router" > router.ts

touch global-middlewares.ts
echo "import { Request, Response, NextFunction } from \"express\"
import jwt from \"jsonwebtoken\"
import Helpers from \"../../helpers/helpers\"
//import { TokenBlackList } from \"../models/tokenblacklist\"

export default class GlobalMiddlewares{

    public static verifyToken(req: Request, res: Response, next: NextFunction){
        const authHeader = req.headers['authorization']
        const token = ( authHeader && authHeader.split(' ')[1] ) || ''

        jwt.verify(token ?? '', process.env.ACCESS_TOKEN_SECRET!, async (err, user: any) => {


            /* let tokenExisting = await TokenBlackList.findOne({
                where: {
                    token: token
                }
            }) */
    
            if (err/*  || tokenExisting */) {
                return res.status(401).send(Helpers.invalidAccessTokenError)
            } else {
                res.locals.id = user.id
                res.locals.token = token
                next()
            }
    
        })
    }

    public static verifyRight(right: string){
        return async (req: Request, res: Response, next: NextFunction) => {
            
            if(res.locals.user.account_type !== right){
                return res.status(403).send(Helpers.accessDeniedError)
            }
            next()
        }
    }
}" > global-middlewares.ts

cd ..

#service file
cd services
touch service.ts
echo "import { ModelStatic, ValidationError } from \"sequelize\";
import Helpers from \"../../helpers/helpers\";


export default class Service {

    protected model: ModelStatic<any>

    constructor(model: ModelStatic<any>){
        this.model = model;
    }

    async getAll(){
        try{
            const data = await this.model.findAll()
            return Helpers.queryResponse(data)
        } catch(err){
            return Helpers.serverError
        }
    }

    async insert(data: any){
        try{
            const item = await this.model.create(data)
            return Helpers.queryResponse(item)
        } catch(error){
            if(error instanceof ValidationError){
                let fields = []
                for(let err of error.errors){
                    fields.push({name: err.path, status: err.validatorKey})
                }
                return Helpers.queryError({msg: 'fields errors', fields})
            }
            return Helpers.serverError
        }
    }

    async update(id: string, data: any){
        try{
            let item = await this.model.findByPk(id);
            if (!item) {
                return Helpers.notFoundError
            }
            item.set(data)
            await item.save()
            return Helpers.queryResponse(item)
        } catch(err){
            if(err instanceof ValidationError){
                let fields = []
                for(let error of err.errors){
                    fields.push({name: error.path, status: error.validatorKey})
                }
                return Helpers.queryError({msg: 'fields errors', fields})
            }
            return Helpers.serverError
        }
    }

    async delete(id: string) {
        try {
            const item = await this.model.findByPk(id);
            if (!item){
                return Helpers.notFoundError;
            }
            await item.destroy()
            return Helpers.queryResponse(item)
        } catch (error) {
            return Helpers.serverError
        }
    }

}" > service.ts

cd ../..

#config files
cd config
touch migrations.ts
echo "
(async () => {
})();" > migrations.ts

touch sequelize.ts
echo "import { Sequelize } from \"sequelize\";
import \"dotenv/config\";

const sequelize = new Sequelize(process.env.DATABASE_NAME as string, process.env.DATABASE_USERNAME as string, process.env.DATABASE_PASSWORD, {
    host: 'localhost',
    dialect: 'mysql',
});

export default sequelize;" > sequelize.ts

cd ..

#helpers files
cd helpers
touch helpers.ts
echo "import { verifyEmailTemplate } from \"./templates/verify-email\";
import nodemailer from \"nodemailer\"
import 'dotenv/config';
import { Twilio } from \"twilio\";
import { resetPasswordTemplate } from \"./templates/reset-password\";

class Helpers{

    public static verifyEmail = verifyEmailTemplate;
    public static resetPassword = resetPasswordTemplate;

    public static mailTransporter = nodemailer.createTransport({
        host: process.env.MAIL_HOST,
        port: parseInt(process.env.MAIL_PORT!),
        secure: false,
        auth: {
            user: process.env.MAIL_USERNAME,
            pass: process.env.MAIL_PASSWORD,
        },
    });

    public static smsTransporter = new Twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

    public static serverError = { is_error: true, status: 'server_error', msg: 'Unknown error occured' }
    public static notFoundError = { is_error: true, status: 'not_found', msg: 'Item not found' }
    public static accessDeniedError = { is_error: true, status: 'access_denied', msg: 'Access denied' }
    public static invalidAccessTokenError = { is_error: true, status: 'invalid_access_token', msg: 'Invalid access token' }
    public static queryResponse(data: any){
        return { is_error: false, data } 
    }
    public static queryError(errors: any){
        return { is_error: true, errors } 
    }  

    public static timeAfterSecond(second: number){
        return Math.floor(Date.now() / 1000) + second
    }

}

export default Helpers;" > helpers.ts

cd templates
touch verify-email.ts
echo "export function verifyEmailTemplate( mail: string, url: string) {
    return \`<!DOCTYPE html>
    <html lang=\"en\">
    <head></head>
    <body>
        <table width=\"100%\" height=\"100%\" style=\"min-width:348px\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" lang=\"en\">
            <tbody>
                <tr height=\"32\" style=\"height:32px\">
                    <td></td>
                </tr>
                <tr align=\"center\">
                    <td>
                        <table border=\"0\" cellspacing=\"0\" cellpadding=\"0\"
                            style=\"padding-bottom:20px;max-width:516px;min-width:220px\">
                            <tbody>
                                <tr>
                                    <td width=\"8\" style=\"width:8px\"></td>
                                    <td>
                                        <div style=\"border-style:solid;border-width:thin;border-color:#dadce0;border-radius:8px;padding:40px 20px\"
                                            align=\"center\">
                                            <img src=\"/dist/assets/logo.png'\" width=\"74\" height=\"24\" aria-hidden=\"true\"
                                                style=\"margin-bottom:16px\" alt=\"Logo\">
                                            <div
                                                style=\"font-family:'Google Sans',Roboto,RobotoDraft,Helvetica,Arial,sans-serif;border-bottom:thin solid #dadce0;color:rgba(0,0,0,0.87);line-height:32px;padding-bottom:24px;text-align:center;word-break:break-word\">
                                                <div style=\"font-size:24px\">Vérifier votre adresse mail</div>
                                                <table align=\"center\" style=\"margin-top:8px\">
                                                    <tbody>
                                                        <tr style=\"line-height:normal\">
                                                            <td align=\"right\" style=\"padding-right:8px\">
                                                                <img width=\"20\" height=\"20\" src=\"/dist/assets/logo.png\"
                                                                    style=\"width:20px;height:20px;vertical-align:sub;border-radius:50%\"
                                                                    alt=\"Badge\">
                                                            </td>
                                                            <td>
                                                                <a
                                                                    style=\"font-family:'Google Sans',Roboto,RobotoDraft,Helvetica,Arial,sans-serif;color:rgba(0,0,0,0.87);font-size:14px;line-height:20px\">${mail}</a>
                                                            </td>
                                                        </tr>
                                                    </tbody>
                                                </table>
                                            </div>
                                            <div
                                                style=\"font-family:Roboto-Regular,Helvetica,Arial,sans-serif;font-size:14px;color:rgba(0,0,0,0.87);line-height:20px;padding-top:20px;text-align:center\">
                                                <b>Bonjour</b>, votre compte a été crée avec succès ! 😍 <br /><br /><br />
                                                Pour vérifier votre adresse mail et profiter pleinement de nos services,
                                                veuillez cliquer sur le lien suivant ( valable 10 minutes ): <br /><br />
                                                <a target=\"_blank\" href=\"${url}\"
                                                    style=\"display: inline-block; padding:10px 24px; background-color: #00B51D; color: #ffffff; text-align: center; text-decoration: none; border-radius: 5px;\">Activer
                                                    mon compte</a>
                                            </div>
                                            <div
                                                style=\"font-family:Roboto-Regular,Helvetica,Arial,sans-serif;font-size:14px;color:rgba(0,0,0,0.87);line-height:20px;padding-top:20px;text-align:center\">
                                                Si vous n'y arrivez pas, merci de cliquer ou copier/coller le lien suivant
                                                dans la barre
                                                d'adresse de votre navigateur: <br />
                                                <a target=\"_blank\"
                                                    href=\"${url}\"
                                                    style=\"display: inline-block; padding:10px 24px; text-align: center; \">${url}</a>
                                            </div>
                                        </div>
                                        <div style=\"text-align:left\">
                                            <div
                                                style=\"font-family:Roboto-Regular,Helvetica,Arial,sans-serif;color:rgba(0,0,0,0.54);font-size:11px;line-height:18px;padding-top:12px;text-align:center\">
                                                <div style=\"direction:ltr\">© 2023 Viit Inc, <a
                                                        class=\"m_3638319201271897461afal\"
                                                        style=\"font-family:Roboto-Regular,Helvetica,Arial,sans-serif;color:rgba(0,0,0,0.54);font-size:11px;line-height:18px;padding-top:12px;text-align:center\">Gordon
                                                        5 rue Tidjiane Thiam, Abidjan</a></div>
                                            </div>
                                        </div>
                                    </td>
                                    <td width=\"8\" style=\"width:8px\"></td>
                                </tr>
                            </tbody>
                        </table>
                    </td>
                </tr>
                <tr height=\"32\" style=\"height:32px\">
                    <td></td>
                </tr>
            </tbody>
        </table>
    </body>
    </html>\`
}" > verify-email.ts

touch reset-password.ts
echo "export function resetPasswordTemplate( mail: string, url: string) {
    return \`<!DOCTYPE html>
    <html lang=\"en\">
    <head></head>
    <body>
        <table width=\"100%\" height=\"100%\" style=\"min-width:348px\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" lang=\"en\">
            <tbody>
                <tr height=\"32\" style=\"height:32px\">
                    <td></td>
                </tr>
                <tr align=\"center\">
                    <td>
                        <table border=\"0\" cellspacing=\"0\" cellpadding=\"0\"
                            style=\"padding-bottom:20px;max-width:516px;min-width:220px\">
                            <tbody>
                                <tr>
                                    <td width=\"8\" style=\"width:8px\"></td>
                                    <td>
                                        <div style=\"border-style:solid;border-width:thin;border-color:#dadce0;border-radius:8px;padding:40px 20px\"
                                            align=\"center\">
                                            <img src=\"/dist/assets/logo.png\" width=\"74\" height=\"24\" aria-hidden=\"true\"
                                                style=\"margin-bottom:16px\" alt=\"Logo\">
                                            <div
                                                style=\"font-family:'Google Sans',Roboto,RobotoDraft,Helvetica,Arial,sans-serif;border-bottom:thin solid #dadce0;color:rgba(0,0,0,0.87);line-height:32px;padding-bottom:24px;text-align:center;word-break:break-word\">
                                                <div style=\"font-size:24px\">Réinitialiser le mot de passe</div>
                                                <table align=\"center\" style=\"margin-top:8px\">
                                                    <tbody>
                                                        <tr style=\"line-height:normal\">
                                                            <td align=\"right\" style=\"padding-right:8px\">
                                                                <img width=\"20\" height=\"20\" src=\"/dist/assets/logo.png\"
                                                                    style=\"width:20px;height:20px;vertical-align:sub;border-radius:50%\"
                                                                    alt=\"Badge\">
                                                            </td>
                                                            <td>
                                                                <a
                                                                    style=\"font-family:'Google Sans',Roboto,RobotoDraft,Helvetica,Arial,sans-serif;color:rgba(0,0,0,0.87);font-size:14px;line-height:20px\">${mail}</a>
                                                            </td>
                                                        </tr>
                                                    </tbody>
                                                </table>
                                            </div>
                                            <div
                                                style=\"font-family:Roboto-Regular,Helvetica,Arial,sans-serif;font-size:14px;color:rgba(0,0,0,0.87);line-height:20px;padding-top:20px;text-align:center\">
                                                <b>Bonjour</b>, <br /><br /><br />
                                                Pour pouvez réinitialiser votre mot de passe en cliquant sur le lien suivant: <br /><br />
                                                <a target=\"_blank\" href=\"${url}\" style=\"display: inline-block; padding:10px 24px; background-color: #00B51D; color: #ffffff; text-align: center; text-decoration: none; border-radius: 5px;\">
                                                    Réinitialiser le mot de passe
                                                </a>
                                            </div>
                                            <div
                                                style=\"font-family:Roboto-Regular,Helvetica,Arial,sans-serif;font-size:14px;color:rgba(0,0,0,0.87);line-height:20px;padding-top:20px;text-align:center\">
                                                Si vous n'y arrivez pas, merci de cliquer ou copier/coller le lien suivant
                                                dans la barre
                                                d'adresse de votre navigateur: <br />
                                                <a target=\"_blank\"
                                                    href=\"${url}\"
                                                    style=\"display: inline-block; padding:10px 24px; text-align: center; \">${url}</a>
                                            </div>
                                        </div>
                                        <div style=\"text-align:left\">
                                            <div
                                                style=\"font-family:Roboto-Regular,Helvetica,Arial,sans-serif;color:rgba(0,0,0,0.54);font-size:11px;line-height:18px;padding-top:12px;text-align:center\">
                                                <div style=\"direction:ltr\">© 2023 Viit Inc, <a
                                                        class=\"m_3638319201271897461afal\"
                                                        style=\"font-family:Roboto-Regular,Helvetica,Arial,sans-serif;color:rgba(0,0,0,0.54);font-size:11px;line-height:18px;padding-top:12px;text-align:center\">Gordon
                                                        5 rue Tidjiane Thiam, Abidjan</a></div>
                                            </div>
                                        </div>
                                    </td>
                                    <td width=\"8\" style=\"width:8px\"></td>
                                </tr>
                            </tbody>
                        </table>
                    </td>
                </tr>
                <tr height=\"32\" style=\"height:32px\">
                    <td></td>
                </tr>
            </tbody>
        </table>
    </body>
    </html>\`
}" > reset-password.ts

cd ../../..

#install default packages
npm install
npm i @types/bcrypt @types/jsonwebtoken @types/nodemailer bcrypt dotenv express twilio uuid
npm i -D @types/express @types/jest @types/supertest @types/uuid jest nodemon supertest ts-jest ts-node typescript
