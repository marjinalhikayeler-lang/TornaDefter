/**
 * TornaDefter - Cari Hesap Takip Sistemi
 * Ana uygulama başlatma dosyası (Bootstrap)
 *
 * Bu dosya NestJS uygulamasını yapılandırır ve başlatır.
 * Swagger, güvenlik, doğrulama ve hız sınırlama ayarlarını içerir.
 */

import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // ============================================
  // Global API ön eki (prefix)
  // ============================================
  app.setGlobalPrefix('api/v1');

  // ============================================
  // CORS yapılandırması - Çapraz kaynak isteklerine izin ver
  // ============================================
  app.enableCors({
    origin: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3001'],
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Company-Id'],
  });

  // ============================================
  // Güvenlik ara katmanları (Security middleware)
  // ============================================
  app.use(helmet()); // HTTP başlık güvenliği
  app.use(compression()); // Yanıt sıkıştırma

  // Hız sınırlama - 15 dakikada maksimum 100 istek
  app.use(
    rateLimit({
      windowMs: 15 * 60 * 1000, // 15 dakika
      max: 100, // Her IP için maksimum istek sayısı
      message: {
        success: false,
        error: {
          code: 'TOO_MANY_REQUESTS',
          message: 'Çok fazla istek gönderdiniz. Lütfen daha sonra tekrar deneyin.',
        },
      },
      standardHeaders: true,
      legacyHeaders: false,
    }),
  );

  // ============================================
  // Global doğrulama borusu (Validation pipe)
  // ============================================
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // DTO'da tanımlı olmayan alanları otomatik kaldır
      forbidNonWhitelisted: true, // Tanımsız alan gönderilirse hata döndür
      transform: true, // Gelen veriyi otomatik dönüştür
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // ============================================
  // Swagger API Dokümantasyonu
  // ============================================
  const swaggerConfig = new DocumentBuilder()
    .setTitle('TornaDefter API')
    .setDescription(
      'TornaDefter Cari Hesap Takip Sistemi API dokümantasyonu. ' +
      'Türk küçük işletmeleri için kapsamlı cari hesap ve finansal yönetim çözümü.',
    )
    .setVersion('1.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'JWT',
        description: 'JWT erişim tokenı girin',
        in: 'header',
      },
      'access-token',
    )
    .addTag('Kimlik Doğrulama', 'Giriş, kayıt ve token yenileme işlemleri')
    .addTag('Kullanıcılar', 'Kullanıcı yönetimi')
    .addTag('Şirketler', 'Şirket/işletme yönetimi')
    .addTag('Cari Hesaplar', 'Müşteri ve tedarikçi cari hesapları')
    .addTag('İşlemler', 'Borç/alacak işlemleri')
    .addTag('Kasa', 'Kasa hesapları ve nakit akışı')
    .addTag('Banka', 'Banka hesapları')
    .addTag('Transferler', 'Hesaplar arası transferler')
    .addTag('Kategoriler', 'İşlem kategorileri')
    .addTag('Çek/Senet', 'Çek ve senet takibi')
    .addTag('Gelir/Gider', 'Gelir ve gider takibi')
    .addTag('Raporlar', 'Finansal raporlar ve analizler')
    .addTag('Bildirimler', 'Bildirim yönetimi')
    .addTag('Yedekleme', 'Veri yedekleme ve geri yükleme')
    .addTag('Abonelikler', 'Abonelik planları ve ödemeler')
    .addTag('Destek', 'Kullanıcı destek talepleri')
    .addTag('Yönetim', 'Sistem yönetim paneli')
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true, // Token'ı tarayıcıda sakla
      tagsSorter: 'alpha',
      operationsSorter: 'alpha',
    },
    customSiteTitle: 'TornaDefter API Dokümantasyonu',
  });

  // ============================================
  // Uygulamayı başlat
  // ============================================
  const port = process.env.PORT || 3000;
  await app.listen(port);
  logger.log(`🚀 TornaDefter API sunucusu ${port} portunda çalışıyor`);
  logger.log(`📚 Swagger dokümantasyonu: http://localhost:${port}/api/docs`);
}

bootstrap();
