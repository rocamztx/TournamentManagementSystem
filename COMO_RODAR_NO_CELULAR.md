# Como rodar no celular com o PC como servidor

## 1. Ver o IP do PC servidor

Execute:

```bat
ver-ip-do-servidor.bat
```

Anote o IPv4 da placa que esta na mesma rede Wi-Fi/cabo dos celulares.

## 2. Liberar a porta 8080 no firewall

Execute como Administrador:

```bat
liberar-firewall-8080.bat
```

## 3. Iniciar o servidor

Antes, garanta que o PostgreSQL esta ligado e que o banco `obr_db` existe.

Execute:

```bat
start-server.bat
```

Se preferir rodar como um servidor empacotado, use:

```bat
build-server-jar.bat
start-server-jar.bat
```

Teste no navegador do celular:

```text
http://IP_DO_PC:8080/api/classificacao/status
```

Se aparecer uma resposta com `api: online`, o servidor esta acessivel.

## 4. Gerar o APK apontando para esse servidor

Execute:

```bat
build-debug-apk.bat
```

Quando ele pedir o IP, informe o IPv4 do PC servidor.

O APK sera gerado em:

```text
frontend\build\app\outputs\flutter-apk\app-debug.apk
```

Instale esse mesmo APK nos celulares. Todos devem estar na mesma rede do PC.

## Teste rapido sem instalar APK

Com o servidor ligado, execute:

```bat
run-web-para-celular.bat
```

Depois abra no navegador do celular:

```text
http://IP_DO_PC:3000
```

## O que fica salvo

As equipes, nomes e pontuacoes ficam no PostgreSQL. Se voce fechar e abrir o
servidor Spring Boot, os dados continuam no banco. Os dados so somem se o banco
for apagado, trocado ou resetado manualmente.
