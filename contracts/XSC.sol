// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

contract XSC {
    // A - Inicialização
    address[] private admins; //Lista de Administradores
    address[] private devices; //Lista de Dispositivos
    address[] private users; //Lista de Usuários
    address[] private aux; //Lista auxiliar

    constructor () { //Declara o endereço que faz o deploy como primeiro admin
        admins.push(msg.sender);
        emit objectAdded(msg.sender, msg.sender);
    }

    struct Token{ //Struct para os dados de um Token
        bytes32 UID;
        address user;
        address dev;
    }

    Token[] private Tokens; //Vetor de todos os tokens emitidos
    Token[] private StructAux; //Struct auxiliar

    //Dispositivos que podem ser acessados por um usuário
    mapping(address => address[]) private user_devices; 


    // B - Adição
    function addAdmin(address newAdmin) public onlyAdmin{
        if(findInList(newAdmin, admins) == -1){ //Verifica se já existe
            admins.push(newAdmin); //Add na lista
            emit objectAdded(newAdmin, msg.sender); //Registra a operação
        }else{
            revert objectAlreadyExists(newAdmin, msg.sender); //Emite o erro
        }
    }

    function addDevice(address newDevice) public onlyAdmin{
        if(findInList(newDevice, devices) == -1){//Verifica se já existe
            devices.push(newDevice);//Add na lista
            emit objectAdded(newDevice, msg.sender); //Registra a operação 
        }else{
            revert objectAlreadyExists(newDevice, msg.sender);//Emite o erro
       }
    }

    function addUser(address newUser) public onlyAdmin{
        if(findInList(newUser, users) == -1){ //Verifica se já existe
            users.push(newUser); //Add na lista
        emit objectAdded(newUser, msg.sender); //Registra a operação
        }else{
            revert objectAlreadyExists(newUser, msg.sender);//Emite o erro
        }
    }

    //Adiciona um dispositivo para um usuário
    function addUserDeviceMapping(address user, address device) public onlyAdmin{
        int cond = findInList(user, users); //Verifica se um usuario está na lista. Caso não, ele não existe 
        if(cond >= 0){
            //User OK
            cond = findInList(device, devices); //Verifica se um dispositivo está na lista. Caso não, ele não existe 
            if(cond >= 0){
                //Device OK
                cond = findMapping(device, user); //Verifica se o mapping está na lista. Caso não, ele não existe   
                if(cond == -1){
                    //mapping OK
                    user_devices[user].push(device);//Cria o mapping
                    emit UserDeviceMappingAdded(user, device, msg.sender);
                }else{
                    revert objectAlreadyExists(user_devices[user][uint(cond)], msg.sender);//mapping já existe
                }
            }else{
                revert objectDoesNotExists(device, msg.sender);//Dispositivo não existe
            } 
        }else{
            revert objectDoesNotExists(user, msg.sender);//Usuário não existe
        }   
    }


    // C - Delete
    //Deletar Admin
    function delAdmin(address admin) public onlyAdmin{
        if(admins.length < 2){//Apenas deleta se existir mais de um Admin 
            revert();
        }else{
            int i = findInList(admin, admins); //Procura o indice
            if(i >= 0){
                delete admins[uint(i)]; //Deleta se existir
                emit objectDeleted(admin, msg.sender);
            }else{
                revert objectDoesNotExists(admin, msg.sender); //Reverte se não existir
            }   
        }
    }

    function delDevice(address device) public onlyAdmin{
        int i = findInList(device, devices);//Procura o indice
        if(i >= 0){
            removeDeviceTokens(device); //remove o acesso
            delete devices[uint(i)]; //Deleta se existir
            emit objectDeleted(device, msg.sender);
        }else{
            revert objectDoesNotExists(device, msg.sender);//Reverte se não existir
        }   
    }

    function delUser(address user) public onlyAdmin{
        int i = findInList(user, users);//Procura o indice
        if(i >= 0){
            delUserAccess(user);//remove o acesso
            delete users[uint(i)];//Deleta se existir
            emit objectDeleted(user, msg.sender);
        }else{
            revert objectDoesNotExists(user, msg.sender);//Reverte se não existir
        }   
    }

    //Deleta o acesso de um usuario para todos os dispositivos
    function delUserAccess(address user) public onlyAdmin{
        if(findInList(user, users) == -1){//Procura o indice
            revert objectDoesNotExists(user, msg.sender);//Reverte se não existir
        }else{
            delete user_devices[user];//remove o acesso
            removeUserTokens(user);//remove o acesso
            emit UserDeviceAllMappingDeleted(user, msg.sender);
        }
    }

    //Deleta o acesso de um usuario para um dispositivo
    function delUserDeviceAccess(address user, address device) public onlyAdmin{
        bool flag = false;
        if(findInList(user, users) == -1){//Procura o indice
            revert objectDoesNotExists(user, msg.sender);//Reverte se não existir user
        }else{
            for(uint i=0; i<user_devices[user].length; i++){
                if(user_devices[user][i] == device){
                    flag = true;
                    delete user_devices[user][i];//remove o acesso
                    emit UserDeviceOneMappingDeleted(user, device, msg.sender);
                    removeAccessToken(device, user);//remove o acesso
                }
            }
            if(!flag){
                revert objectDoesNotExists(device, msg.sender);//Reverte se não existir device
            }
        }
    }

    //Deleta o token de uma autenticação
    function removeAccessToken(address device, address user) public onlyAdmin{
        bool flag = false;
        bytes32 UID;
        for(uint i=0; i<Tokens.length; i++){
            if(Tokens[i].dev == device && Tokens[i].user == user){//Procura o token
                UID = Tokens[i].UID;
                delete Tokens[i]; //Deleta o Token
                flag = true;
                emit TokenDeleted(UID, user, device, msg.sender);
            }
        }
        if(!flag){
            emit TokenDoesNotExists();//Reverte se não existir o token
        }
    }

    //Deleta todos os tokens de um dispositivo
    function removeDeviceTokens(address device) public onlyAdmin{ 
        bool flag = false;
        if(findInList(device, devices) == -1){
            revert objectDoesNotExists(device, msg.sender);
        }else{
            uint i;
            for(i=0; i<Tokens.length; i++){
                if(Tokens[i].dev == device){
                    flag = true;
                    delete Tokens[i];
                    emit TokenDeleted(Tokens[i].UID, Tokens[i].user, Tokens[i].dev, msg.sender);
                }
            }if(!flag){
                emit TokenDoesNotExists();
            }
        }
    }

    //Deleta todos os tokens de um usuario
    function removeUserTokens(address user) public onlyAdmin{
        bool flag = false;
        if(findInList(user, users) == -1){
            revert objectDoesNotExists(user, msg.sender);
        }else{
            uint i;
            for(i=0; i<Tokens.length; i++){
                if(Tokens[i].user == user){
                    flag = true;
                    delete Tokens[i];
                    emit TokenDeleted(Tokens[i].UID, Tokens[i].user, Tokens[i].dev, msg.sender);
                }
            }if(!flag){
                emit TokenDoesNotExists();
            }
        }
    }


    // D - Autenticação
    //Requisição de Autenticação
    function requestAuthentication(address device) public{
        if(findInList(device, devices) >= 0){
            //Dispositivo existe
            if(findInList(msg.sender, users) >= 0){
                //User existe
                if(findMapping(device, msg.sender) >= 0){
                    //Mapping existe
                    //Emite o evento de autenticação bem-sucedida
                    emit Authenticated(msg.sender, device);
                    bool tokenCheck = false;
                    for(uint i=0; i<Tokens.length; i++){
                        if(Tokens[i].dev == device && Tokens[i].user == msg.sender){
                            // Token já existe
                            tokenCheck = true;
                        }
                    }
                    if(!tokenCheck){
                        //Cria um novo Token
                        bytes32 UID = keccak256(abi.encodePacked(device, msg.sender, block.timestamp));
                        Tokens.push(Token(UID, msg.sender, device));
                        emit TokenCreated(UID, msg.sender, device);
                    }else{
                        emit TokenAlreadyExists(msg.sender, device);
                    }
                }else{
                    //Emite o evento de autenticação malsucedida - mapping não existe
                    revert NotAuthenticated(msg.sender);
                }
            }else{
                //User não existe
                revert objectDoesNotExists(msg.sender, msg.sender);
            }
        }else{
            //Device não existe
            revert objectDoesNotExists(device, msg.sender);
        }
    }


    // E - Funcionalidades
    //Retorna o indice de um objeto na lista ou -1 caso ele não exista
    function findInList(address obj, address[] memory local) private pure returns(int){
        int result = -1;
        for(uint i=0; i<local.length; i++){
            if(local[i] == obj){
                result = int(i);
                break;
            }
        }
        return result;
    }

    //Retorna o indice de um mapping ou -1 caso ele não exista
    function findMapping(address device, address user) private view returns(int){
        int result = -1;
        for(uint i=0; i<user_devices[user].length; i++){
            if(user_devices[user][i] == device){
                result = int(i);
                break;
            }
        }
        return result;
    }

    //Chama as funções de limpar o sistema
    function optimizeStorage() public onlyAdmin{
        removeZerosAdmins();
        removeZerosDevices();
        removeZerosUsers();
        removeZerosTokens();
        emit SystemStorageOptimized(msg.sender);
    }

    function removeZerosAdmins() private onlyAdmin{ 
        //0x0000000000000000000000000000000000000000 - address
        uint i = 0;
        while(i<admins.length){
            if(admins[i] != 0x0000000000000000000000000000000000000000){
                aux.push(admins[i]);
            }
            i++;
        }
        delete admins;
        admins = aux;
        delete aux;
    }

    function removeZerosDevices() private onlyAdmin{ 
        uint i = 0;
        while(i<devices.length){
            if(devices[i] != 0x0000000000000000000000000000000000000000){
                aux.push(devices[i]);
            }
            i++;
        }
        delete devices;
        devices = aux;
        delete aux;
    }

    function removeZerosTokens() private onlyAdmin{ 
        //0x0000000000000000000000000000000000000000000000000000000000000000 - UID
        uint i = 0;
        while(i<Tokens.length){
            if(Tokens[i].UID != 0x0000000000000000000000000000000000000000000000000000000000000000){
                StructAux.push(Tokens[i]);
            }
            i++;
        }
        delete Tokens;
        Tokens = StructAux;
        delete StructAux;
    }

    function removeZerosUsers() private onlyAdmin{ 
        uint i = 0;
        while(i<users.length){
            if(users[i] != 0x0000000000000000000000000000000000000000){
                aux.push(users[i]);
            }
            i++;
        }
        delete users;
        users = aux;
        delete aux;
    }

    function showAdmins() public view returns (address[] memory){ //Exibe os Admins
        return admins;
    }

    function showDevices() public view returns (address[] memory){ //Exibe os Dispositivos
        return devices;        
    }

    function showTokens() public view returns (Token[] memory){ //Exibe os Tokens
        return Tokens;        
    }

    function showUserDevicesMap(address user) public view returns (address[] memory){
        return user_devices[user];
    }

    function showUsers() public view returns (address[] memory){ //Exibe os Usuários
        return users;        
    }


    // Modificadores
    //Apenas Admins podem executar certas funções
    modifier onlyAdmin{ //Para verificar o usuário
        bool admin = false;
        for(uint i=0; i< admins.length; i++){ //Percorre a lista de Admins
            if(msg.sender == admins[i]){ //Verifica se o usuário está na lista de Admins
                admin = true;
                break;
            }
        }
        if(!admin){
            revert(); //Cancela
        }else{
            _; //Continua
        }
    }


    // Eventos
    //Autenticação bem-sucedida
    event Authenticated(address user, address device);

    //Criação de um objeto e quem criou
    event objectAdded(address newAddress, address admin);

    //Exclusão de um Admin e por quem
    event objectDeleted(address deletedObj, address admin);

    //Limpeza das variáveis do sistema - remoção dos endereços vazios (0x000...)
    event SystemStorageOptimized(address admin);

    //Token já existe no sistema
    event TokenAlreadyExists(address user, address device);

    //Token criado
    event TokenCreated(bytes32 uid, address user, address device);

    //Exclusão de um Token
    event TokenDeleted(bytes32 UID, address user, address device, address admin);

    //Token não existe
    event TokenDoesNotExists();

    //Exclusão dos mappings usuario-dispositivos de um usuario e por quem
    event UserDeviceAllMappingDeleted(address user, address admin);

    //Criação de um mapping usuario-dipositivo e quem criou
    event UserDeviceMappingAdded(address user, address device, address admin);

    //Exclusão do mapping de um usuario para um dispositivo
    event UserDeviceOneMappingDeleted(address user, address device, address admin);


    // Erros
    //Autenticação malsucedida
    error NotAuthenticated(address user);

    //O objeto a ser criado já existe no sistema
    error objectAlreadyExists(address obj, address sender);

    //O objeto requisitado não existe no sistema
    error objectDoesNotExists(address obj, address sender);

}