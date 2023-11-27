# Use a imagem oficial do Node.js
FROM node:14

# Crie e defina o diretório de trabalho
WORKDIR /usr/src/app

# Copie o conteúdo do diretório da sua aplicação para o contêiner
COPY . .

# Instale as dependências
RUN npm install

# Exponha a porta 8080 (ou a porta que o Live Server está usando)
EXPOSE 8080

# Comando para iniciar o Live Server
CMD ["npx", "live-server"]

