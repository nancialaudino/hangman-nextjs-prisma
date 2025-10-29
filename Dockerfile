
# Étape 1 : image de base

# On part d'une image officielle Node.js légère
FROM node:20-slim AS base

# On définit le répertoire de travail à l'intérieur du conteneur
WORKDIR /app


# Étape 2 : construction de l'application

##############################################
FROM base AS builder

# On copie uniquement les fichiers de dépendances en premier
# (cela permet de tirer parti du cache Docker si les dépendances n'ont pas changé)
COPY package*.json ./

# On installe les dépendances du projet avec "npm ci"
RUN npm ci

# On copie tout le code source du projet dans le conteneur
COPY . .

# On exécute la commande de build (Next.js génère le dossier .next)
RUN npm run build


# Étape 3 : image finale pour la production

##############################################
FROM base AS runner

# On crée un utilisateur non-root (sécurité)
USER node

# On copie les fichiers nécessaires depuis l'étape "builder"
# On change aussi le propriétaire des fichiers pour l'utilisateur "node"
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/package*.json ./
COPY --from=builder --chown=node:node /app/.next ./.next
COPY --from=builder --chown=node:node /app/public ./public
COPY --from=builder --chown=node:node /app/prisma ./prisma

# On expose le port 3000 pour accéder à l'application
EXPOSE 3000

# On définit l'environnement de production
ENV NODE_ENV=production

# Commande de démarrage du serveur Next.js
CMD ["npm", "run", "start"]
