# Use a imagem oficial do Node.js
FROM node:14

# Crie e defina o diretório de trabalho
WORKDIR /usr/src/app

# Copie o conteúdo do diretório da sua aplicação para o contêiner
COPY . .

# Instale as dependências
RUN npm install
