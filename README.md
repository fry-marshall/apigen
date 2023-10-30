# Apigen

Apigen is an opensource project that allows to create easily a RESTFUL api using nodejs.
It's based on **typescript** and use the ORM **sequelize**.



## Installation

First of all, you need to have Node Installed.
If it's not you can install through this link: https://nodejs.org/en/

Clone this project and follow instructions below:

## Run Locally

#### Clone the project

```bash
git clone https://github.com/projet-qualite/apigen.git
```

#### Open the file to create an alias

```bash
nano ~/.zshrc    
```

#### Create alias ( Mac OS and Linux )


```bash
alias genmodel="bash /Users/kangacedricmarshallfry/Desktop/DEV/Apigen/gen-model/main.sh $1"
alias apigen="bash /Users/kangacedricmarshallfry/Desktop/DEV/Apigen/init/main.sh $1"
alias genmodeluser="bash /Users/kangacedricmarshallfry/Desktop/DEV/Apigen/gen-default-user/main.sh"
```

#### Store the changes

```bash
source ~/.zshrc 
```

#### Create your project

```bash
apigen your-project-name
```


#### Rename the env.example file to .env

```bash
ACCESS_TOKEN_SECRET=
REFRESH_TOKEN_SECRET=
PORT=
HOST_NAME=
DATABASE_NAME=
DATABASE_PASSWORD=
DATABASE_USERNAME=
MAIL_HOST=
MAIL_PORT=
MAIL_USERNAME=
MAIL_PASSWORD=
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_NUMBER=
FCM_SERVER_KEY=
```
These following fields are required: 
```bash
PORT=
DATABASE_NAME=
DATABASE_PASSWORD=
DATABASE_USERNAME=
```

⚠️ In a case you use the default user model you must algo fill these fields:
```bash
ACCESS_TOKEN_SECRET=
REFRESH_TOKEN_SECRET=
MAIL_HOST=
MAIL_PORT=
MAIL_USERNAME=
MAIL_PASSWORD=
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_NUMBER=
```

#### Create your model
```bash
genmodel model-name
```
It will create default files corresponding to the model in these folders:
* **src/app/controllers/modelNameController.ts**: the default CRUD fonctions are already defined since it inherit from Controller class so, you can redirect to yourself if you need more specifications
* **src/app/models/model-name.ts**: By default only the id is defined as field, you can easily update depending on your needs
* **src/app/routes/model-name**: you will find all the default routes defined ( post, get, update, delete ) and also a middleware file to defined the specific middleware for those endpoints
* **src/tests/model-name.test.ts**: default file to create your unit tests
* **src/app/services/modelNameService**: the default services fonctions ( Normally you don't need to touch to this file )


#### Create a default user model ( Optionnal )
```bash
genmodeluser
```
👨🏽‍💻 it will create all default elements a user table needs ( login, logout, signin), all the routes by default, you can adjust it depending on your needs


#### Export your models to the database
```bash
make migrate
```


#### Run your app
```bash
make start
```

#### Run your tests
```bash
make test
```

⚠️ In the file **src/config/migrations.ts** you have all the 
models that should be exported in the database. If there are some links
between some models like for example a 1:n association, it's through this file
you have to add that one.
## 🚀 About Me
I'm Marshall FRY a junior full stack developer. I like to create & learn new thing about technologies.
You can find more information about me at the link: https://mfry.io


## Tech Stack

**Server:** Node, Express, Shell, Typescript, Jest


## License

[MIT](https://choosealicense.com/licenses/mit/)

