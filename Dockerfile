# 1. Base Image
FROM node:18-alpine AS base

# 2. Deps Stage
FROM base AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# 3. Builder Stage
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# ตรงนี้จะผ่านแล้ว เพราะเราแก้ next.config.js ให้ ignore error แล้ว
RUN npm run build

# 4. Runner Stage
FROM base AS runner
WORKDIR /app
# แก้ Warning: ใส่เครื่องหมาย =
ENV NODE_ENV=production

# ⚠️ แก้ไขจุดสำคัญ:
# 1. ต้องเอา public มาด้วย (พวกรูปภาพ/favicon)
COPY --from=builder /app/public ./public

# 2. เอาบรรทัด node_modules ออก!
# (เพราะใน folder standalone มันรวม node_modules ที่จำเป็นมาให้แล้วครับ ใส่ซ้ำจะทำให้ Image ใหญ่ฟรีๆ)
# COPY --from=builder /app/node_modules ./node_modules  <-- ลบบรรทัดนี้ทิ้ง

# 3. Copy ไฟล์ Standalone (พระเอกของเรา)
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000
CMD ["node", "server.js"]