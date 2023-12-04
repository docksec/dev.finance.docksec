# Use a imagem oficial do Node.js
FROM node:16.2.0

# Crie e defina o diretório de trabalho
WORKDIR /usr/src/app

# Copie o conteúdo do diretório da sua aplicação para o contêiner
COPY . .
