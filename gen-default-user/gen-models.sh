#!/bin/bash

#generate models
cd src/app/models

touch user.ts
echo "import { DataTypes, Model } from \"sequelize\";
import bcrypt from \"bcrypt\";
import sequelize from \"../../config/sequelize\";

interface UserAttributes{
    id: string;
    firstname: string,
    lastname: string,
    indicative: string,
    phone: string;
    phone_verified_digits: string;
    phone_expiredtime: string;
    phone_verified: boolean;
    email: string;
    email_verified_token: string;
    email_expiredtime: string;
    email_verified: boolean;
    forgotpasswordtoken: string,
    forgotpasswordused: boolean
    password: string;
    account_type: string;
    status: boolean;
}

interface UserInstance extends Model<UserAttributes>, UserAttributes{}

const User = sequelize.define<UserInstance>('user', {
    id: {
        type: DataTypes.STRING,
        primaryKey: true,
        unique: true,
    },
    firstname: {
        type: DataTypes.STRING,
        validate: {
            notEmpty: true
        }
    },
    lastname: {
        type: DataTypes.STRING,
        validate: {
            notEmpty: true
        }
    },
    indicative: {
        type: DataTypes.STRING,
        allowNull: false,
        validate: {
            notEmpty: true
        },
        set(value){
            if(value !== \"+33\" && value !== \"+225\"){
                this.setDataValue('indicative', '+225')
            }else{
                this.setDataValue('indicative', value)
            }
        }
    },
    phone: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
        validate: {
            notEmpty: true,
            len: [10, 10],
            invalidNumber(value: string){
                if(!(/^\d{10}$/.test(value))){
                    throw new Error('Invalid phone number');
                }
            }
        }
    },
    phone_verified_digits: {
        type: DataTypes.STRING,
        allowNull: false,
        defaultValue: '',
        validate: {
            notEmpty: true,
        }
    },
    phone_expiredtime: {
        type: DataTypes.STRING,
        allowNull: true,
        defaultValue: ''
    },
    phone_verified: {
        type: DataTypes.BOOLEAN,
        defaultValue: false
    },
    email: {
        type: DataTypes.STRING,
        unique: true,
        validate: {
            isEmail: true,
        }
    },
    email_verified_token: {
        type: DataTypes.STRING,
        allowNull: true,
        defaultValue: '',
        validate: {
            notEmpty: true,
        }
    },
    email_expiredtime: {
        type: DataTypes.STRING,
        allowNull: false,
        defaultValue: ''
    },
    email_verified: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false
    },
    forgotpasswordtoken: {
        type: DataTypes.STRING,
    },
    forgotpasswordused: {
        type: DataTypes.BOOLEAN,
        defaultValue: false
    },
    password: {
        type: DataTypes.STRING,
        allowNull: false,
        validate: {
            notEmpty: true
        },
        set(value: string){
            if(typeof value !== \"undefined\"){
                this.setDataValue('password', bcrypt.hashSync(value, 10));
            }
        }
    },
    account_type: {
        type: DataTypes.ENUM('AD', 'NL'),
        allowNull: false,
        defaultValue: 'NL',
        validate: {
            isIn: [['AD', 'NL']]
        }
    },
    status: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false
    },
})

export { User, UserInstance, UserAttributes};" > user.ts

#tokenblacklist model
touch tokenblacklist.ts
echo "import { DataTypes, Model } from \"sequelize\";
import { v4 as uuidv4 } from \"uuid\";
import sequelize from \"../../config/sequelize\";

interface TokenBlackListAttributes{
    id?: string;
    token: string;
}

interface TokenBlackListInstance extends Model<TokenBlackListAttributes>, TokenBlackListAttributes{}

const TokenBlackList = sequelize.define<TokenBlackListInstance>('tokenblacklist', {
    id: {
        type: DataTypes.STRING,
        primaryKey: true,
        set(value){
            this.setDataValue('id', uuidv4())
        }
    },
    token: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
    }, 
})

export { TokenBlackList, TokenBlackListInstance, TokenBlackListAttributes};" > tokenblacklist.ts

cd ..