# ==================================
# TornaDefter Backend - Çok aşamalı Docker derlemesi
# ==================================

# ---- Derleme aşaması (Build stage) ----
FROM node:20-alpine AS builder

# Çalışma dizinini ayarla
WORKDIR /app

# Bağımlılık dosyalarını kopyala
COPY package*.json ./
COPY prisma ./prisma/

# Bağımlılıkları yükle
RUN npm ci

# Prisma istemcisini oluştur
RUN npx prisma generate

# Kaynak kodunu kopyala
COPY . .

# Uygulamayı derle
RUN npm run build

# ---- Üretim aşaması (Production stage) ----
FROM node:20-alpine AS production

# Güvenlik: root olmayan kullanıcı oluştur
RUN addgroup -g 1001 -S nestjs && \
    adduser -S nestjs -u 1001

WORKDIR /app

# Sadece üretim bağımlılıklarını yükle
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci --only=production && \
    npx prisma generate && \
    npm cache clean --force

# Derleme çıktısını kopyala
COPY --from=builder /app/dist ./dist

# Sahipliği değiştir
RUN chown -R nestjs:nestjs /app

# Root olmayan kullanıcıya geç
USER nestjs

# Sağlık kontrolü
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/v1/health || exit 1

# Portu belirt
EXPOSE 3000

# Uygulamayı başlat
CMD ["node", "dist/main"]
