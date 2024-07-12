# SFDX Commands

# Autorizations

### Login into org

```bash
sfdx org open --target-org repsol--prod --url-only
```

### Authorize someone with my credentials

```bash
sfdx force:auth:device:login --setalias repsol--prod --instanceurl https://repsol.my.salesforce.com --setdefaultusername
```

> Lo ejecuta quien quiera darle acceso y yo. Le pido que me pase el código, y con mis credenciales y ese código me logueo en el entorno
> 

### Authorize via JWT

1. Ejecutamos el siguiente código en el terminal
    
    ```bash
    openssl genrsa -des3 -passout pass:---- -out server.pass.key 2048openssl rsa -passin pass:---- -in server.pass.key -out server.keyopenssl req -new -key server.key -out server.csropenssl x509 -req -sha256 -days 365 -in server.csr -signkey server.key -out server.crt
    ```
    
2. Rellenamos como procede los datos que nos pide [[Pasted image 20230712104059.png]]
3. Recuperamos la *consumer key* y *consumer secret* de la connected app del usuario con el que queremos logarnos.
4. Accedemos a la connected app (Setup > App Manager) buscamos en la lista, `View` y dentro de la app pulsamos en `Edit`.
5. Marcamos el check de Use digital signatures e importamos el fichero antes generado **server.crt**
6. En nuestro terminal, ejecutamos:

   ```bash
  sfdx auth jwt grant --username [username_del_usuario_a_logar] --client-id [client_id_del_user_entre_comillas] --jwt-key-file [fichero_serverkey_generado] --instance-url https://login.salesforce.com -a [alias]sfdx auth jwt grant --username serviciosmtohogar@repsol.com.prod --client-id '3MVG99qusVZJwhsk77DP[...].qY9J.3mJLq5BI.A3[...]u7NEN' --jwt-key-file server.key --instance-url https://login.salesforce.com -a repsol--prod-CPSVA-int
   ```
