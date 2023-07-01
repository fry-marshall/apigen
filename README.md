
# Apigen

Apigen is an opensource project that allows to create easily a RESTFUL api using nodejs.
It only works with **mysql database** and use the ORM **sequelize**.




## Installation

First of all, you need to have Node Installed.
If it's not you can install through this link: https://nodejs.org/en/

Clone this project and follow the following instructions:

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
  alias apigen="bash /path-to-the-directory/apigen/main.sh $1"
  alias genmodel="bash /path-to-the-directory/apigen/g-model.sh
  alias genmodel="bash /path-to-the-directory/apigen/g-user.sh $1"
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
  PORT=port number
  DATABASE_NAME=
  DATABASE_PASSWORD=
  DATABASE_USERNAME=
```

**Copy and paste router.js and migration.js at your project root**

#### Create your model
```bash
  genmodel model-name
```
⚠️By default **identifier** ( id of the table) is created. 
You can modify the properties of the table into /utils/models/_model-name_.js


#### Export your models to the database
```bash
  npm run migrate
```


#### Run your app
```bash
  npm run dev
```

⚠️ In the file _utils/database/migrations.js_ you have all the 
models that should be exported into the database. If there are some links
between some models like for example a 1:n association, it's into this file
you have to add this one.
## 🚀 About Me
I'm a junior full stack developer.
You can find more information about me at the link: https://frymarshall.com


## Tech Stack

**Server:** Node, Express, Shell


## License

[MIT](https://choosealicense.com/licenses/mit/)


# Apigen

Apigen is an opensource project that allows to create easily a RESTFUL api using nodejs.
It only works with **mysql database** and use the ORM **sequelize**.




## Installation

First of all, you need to have Node Installed.
If it's not you can install through this link: https://nodejs.org/en/

Clone this project and follow the following instructions:

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
  alias apigen="bash /path-to-the-directory/apigen/main.sh $1"
  alias genmodel="bash /path-to-the-directory/apigen/g-model.sh
  alias genmodeluser="bash /path-to-the-directory/apigen/g-user.sh $1"
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
  DATABASE_NAME=
  DATABASE_PASSWORD=
  DATABASE_USERNAME=
```


#### Create your model
```bash
  genmodel model-name
```
⚠️By default **identifier** ( id of the table) is created. 
You can modify the properties of the table into /src/app/models/model-name.ts


#### Create user model ( Optionnal )
```bash
  genmodeluser
```
👨🏽‍💻 it will create all default elements a user table needs ( login, logout, signin), all the routes by default, you can adjust it depending on your needs


#### Export your models to the database
```bash
  npm run migrate
```


#### Run your app
```bash
  npm run dev
```

⚠️ In the file src/config/migrations.ts you have all the 
models that should be exported in the database. If there are some links
between some models like for example a 1:n association, it's through this file
you have to add that one.
## 🚀 About Me
I'm a junior full stack developer.
You can find more information about me at the link: https://mfry.io


## Tech Stack

**Server:** Node, Express, Shell, Typescript


## License

[MIT](https://choosealicense.com/licenses/mit/)

