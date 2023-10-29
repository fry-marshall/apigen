#!/bin/bash

#generate services
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

export default UserService" > user-service.ts

#tokenblacklist service
touch tokenblacklist-service.ts
echo "import { ModelStatic } from \"sequelize\";
import Service from \"./service\";

    
class TokenBlackListService extends Service {
    
    constructor(model: ModelStatic<any>) {
        super(model)
    }
}

export default TokenBlackListService" > tokenblacklist-service.ts

cd ..