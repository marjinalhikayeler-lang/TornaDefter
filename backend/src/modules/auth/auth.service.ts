/**
 * Auth Service - Kimlik Doğrulama İş Mantığı
 * Kayıt, giriş, JWT üretme, şifre sıfırlama
 */
import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { PrismaService } from '../../prisma/prisma.service';
import {
  RegisterDto,
  LoginDto,
  RefreshTokenDto,
  ForgotPasswordDto,
  ResetPasswordDto,
  ChangePasswordDto,
} from './dto/auth.dto';
import * as crypto from 'crypto';

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || 'tornadefter_default_key_32chars!';
const IV_LENGTH = 16;

function encryptPassword(password: string): string {
  const iv = crypto.randomBytes(IV_LENGTH);
  const key = Buffer.from(ENCRYPTION_KEY.padEnd(32, '0').slice(0, 32));
  const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
  let encrypted = cipher.update(password);
  encrypted = Buffer.concat([encrypted, cipher.final()]);
  return iv.toString('hex') + ':' + encrypted.toString('hex');
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly MAX_LOGIN_ATTEMPTS = 5;
  private readonly LOCK_DURATION_MIN = 15;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Yeni kullanıcı kaydı
   */
  async register(dto: RegisterDto) {
    // Şifre eşleşme kontrolü
    if (dto.password !== dto.password_confirm) {
      throw new BadRequestException('Şifreler eşleşmiyor.');
    }

    // Kullanım koşulları onayı
    if (!dto.terms_accepted) {
      throw new BadRequestException('Kullanım koşullarını kabul etmelisiniz.');
    }

    // E-posta mükerrer kontrolü
    const existingEmail = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase().trim() },
    });
    if (existingEmail) {
      throw new ConflictException('Bu e-posta adresi zaten kayıtlı.');
    }

    // Telefon mükerrer kontrolü
    if (dto.phone) {
      const existingPhone = await this.prisma.user.findUnique({
        where: { phone: dto.phone },
      });
      if (existingPhone) {
        throw new ConflictException('Bu telefon numarası zaten kayıtlı.');
      }
    }

    // Şifreyi hashle (argon2 yerine bcrypt - yaygın destek)
    const passwordHash = await bcrypt.hash(dto.password, 12);
    const passwordEncrypted = encryptPassword(dto.password);

    // Kullanıcıyı oluştur
    const user = await this.prisma.user.create({
      data: {
        email: dto.email.toLowerCase().trim(),
        phone: dto.phone || null,
        password_hash: passwordHash,
        password_encrypted: passwordEncrypted,
        first_name: dto.first_name.trim(),
        last_name: dto.last_name.trim(),
      },
    });

    // Ücretsiz plan ile abonelik oluştur
    const freePlan = await this.prisma.plan.findFirst({
      where: { slug: 'free', is_active: true },
    });
    if (freePlan) {
      await this.prisma.subscription.create({
        data: {
          user_id: user.id,
          plan_id: freePlan.id,
          status: 'TRIAL',
          trial_ends_at: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // 14 gün
        },
      });
    }

    // Token oluştur
    const tokens = await this.generateTokens(user.id, user.email);

    // Oturum kaydet
    await this.createSession(user.id, tokens, {
      device_name: 'İlk Kayıt',
      device_type: 'unknown',
    });

    this.logger.log(`Yeni kullanıcı kaydı: ${user.email}`);

    return {
      user: this.sanitizeUser(user),
      ...tokens,
    };
  }

  /**
   * Kullanıcı girişi
   */
  async login(dto: LoginDto, ip?: string) {
    // E-posta veya telefon ile kullanıcıyı bul
    const identifier = dto.identifier.toLowerCase().trim();
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [{ email: identifier }, { phone: identifier }],
        deleted_at: null,
      },
    });

    if (!user) {
      throw new UnauthorizedException('E-posta/telefon veya şifre hatalı.');
    }

    // Hesap aktif mi?
    if (!user.is_active) {
      throw new UnauthorizedException('Hesabınız devre dışı bırakılmış. Destek ile iletişime geçin.');
    }

    // Hesap kilitli mi?
    if (user.locked_until && user.locked_until > new Date()) {
      const remaining = Math.ceil((user.locked_until.getTime() - Date.now()) / 60000);
      throw new UnauthorizedException(
        `Hesabınız kilitlendi. ${remaining} dakika sonra tekrar deneyin.`,
      );
    }

    // Şifre kontrolü
    const isPasswordValid = await bcrypt.compare(dto.password, user.password_hash);
    if (!isPasswordValid) {
      // Hatalı deneme sayısını artır
      const attempts = user.failed_login_attempts + 1;
      const updateData: any = { failed_login_attempts: attempts };

      if (attempts >= this.MAX_LOGIN_ATTEMPTS) {
        updateData.locked_until = new Date(
          Date.now() + this.LOCK_DURATION_MIN * 60 * 1000,
        );
        this.logger.warn(`Hesap kilitlendi: ${user.email} (${attempts} hatalı deneme)`);
      }

      await this.prisma.user.update({
        where: { id: user.id },
        data: updateData,
      });

      const remainingAttempts = this.MAX_LOGIN_ATTEMPTS - attempts;
      if (remainingAttempts > 0) {
        throw new UnauthorizedException(
          `E-posta/telefon veya şifre hatalı. ${remainingAttempts} deneme hakkınız kaldı.`,
        );
      } else {
        throw new UnauthorizedException(
          `Çok fazla hatalı deneme. Hesabınız ${this.LOCK_DURATION_MIN} dakika süreyle kilitlendi.`,
        );
      }
    }

    // Başarılı giriş - sayaçları sıfırla
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        failed_login_attempts: 0,
        locked_until: null,
        last_login_at: new Date(),
      },
    });

    // Şifre değişikliği zorunlu mu?
    if (user.must_change_password) {
      return {
        must_change_password: true,
        temp_token: this.jwtService.sign(
          { sub: user.id, type: 'password_change' },
          { expiresIn: '10m' },
        ),
        message: 'Şifrenizi değiştirmeniz gerekiyor.',
      };
    }

    // Token üret
    const tokens = await this.generateTokens(user.id, user.email);

    // Oturum oluştur
    await this.createSession(user.id, tokens, {
      device_name: dto.device_name,
      device_type: dto.device_type,
      ip_address: ip,
    });

    // Denetim kaydı
    await this.prisma.auditLog.create({
      data: {
        user_id: user.id,
        action: 'LOGIN',
        entity_type: 'user',
        entity_id: user.id,
        ip_address: ip,
      },
    });

    // Kullanıcının firmalarını getir
    const companies = await this.prisma.companyUser.findMany({
      where: { user_id: user.id },
      include: {
        company: {
          select: {
            id: true,
            name: true,
            logo_url: true,
            default_currency: true,
          },
        },
      },
    });

    return {
      user: this.sanitizeUser(user),
      companies: companies.map((cu) => ({
        ...cu.company,
        role: cu.role,
      })),
      ...tokens,
    };
  }

  /**
   * Token yenileme
   */
  async refreshToken(dto: RefreshTokenDto) {
    try {
      const payload = this.jwtService.verify(dto.refresh_token, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });

      const tokenHash = this.hashToken(dto.refresh_token);
      const session = await this.prisma.userSession.findFirst({
        where: {
          user_id: payload.sub,
          refresh_token_hash: tokenHash,
          expires_at: { gt: new Date() },
          deleted_at: null,
        },
      });

      if (!session) {
        throw new UnauthorizedException('Geçersiz yenileme tokenı.');
      }

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });

      if (!user || !user.is_active) {
        throw new UnauthorizedException('Hesap bulunamadı veya devre dışı.');
      }

      // Yeni tokenlar üret
      const tokens = await this.generateTokens(user.id, user.email);

      // Eski oturumu güncelle
      await this.prisma.userSession.update({
        where: { id: session.id },
        data: {
          token_hash: this.hashToken(tokens.access_token),
          refresh_token_hash: this.hashToken(tokens.refresh_token),
          expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          last_active_at: new Date(),
        },
      });

      return tokens;
    } catch (error) {
      throw new UnauthorizedException('Geçersiz veya süresi dolmuş token.');
    }
  }

  /**
   * Şifremi unuttum
   */
  async forgotPassword(dto: ForgotPasswordDto) {
    const identifier = dto.identifier.toLowerCase().trim();
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [{ email: identifier }, { phone: identifier }],
        deleted_at: null,
      },
    });

    // Güvenlik: kullanıcı bulunamasa bile aynı mesajı döndür
    if (!user) {
      return { message: 'Şifre sıfırlama bağlantısı gönderildi.' };
    }

    // Sıfırlama tokenı üret (1 saat geçerli)
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenHash = this.hashToken(resetToken);

    // TODO: E-posta veya SMS gönder
    this.logger.log(`Şifre sıfırlama tokenı: ${user.email} - ${resetToken}`);

    return { message: 'Şifre sıfırlama bağlantısı gönderildi.' };
  }

  /**
   * Şifre sıfırlama
   */
  async resetPassword(dto: ResetPasswordDto) {
    // TODO: Token doğrulama implementasyonu
    return { message: 'Şifreniz başarıyla değiştirildi. Yeni şifrenizle giriş yapabilirsiniz.' };
  }

  /**
   * Şifre değiştirme (giriş yapmış kullanıcı)
   */
  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new BadRequestException('Kullanıcı bulunamadı.');
    }

    const isValid = await bcrypt.compare(dto.current_password, user.password_hash);
    if (!isValid) {
      throw new BadRequestException('Mevcut şifreniz hatalı.');
    }

    const newHash = await bcrypt.hash(dto.new_password, 12);
    const newEncrypted = encryptPassword(dto.new_password);
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        password_hash: newHash,
        password_encrypted: newEncrypted,
        must_change_password: false,
      },
    });

    // Denetim kaydı
    await this.prisma.auditLog.create({
      data: {
        user_id: userId,
        action: 'PASSWORD_RESET',
        entity_type: 'user',
        entity_id: userId,
      },
    });

    return { message: 'Şifreniz başarıyla değiştirildi.' };
  }

  /**
   * Çıkış
   */
  async logout(userId: string, tokenHash: string) {
    await this.prisma.userSession.updateMany({
      where: { user_id: userId, token_hash: tokenHash },
      data: { deleted_at: new Date() },
    });

    return { message: 'Oturum başarıyla kapatıldı.' };
  }

  /**
   * Tüm oturumları kapat
   */
  async logoutAll(userId: string) {
    await this.prisma.userSession.updateMany({
      where: { user_id: userId, deleted_at: null },
      data: { deleted_at: new Date() },
    });

    return { message: 'Tüm oturumlar kapatıldı.' };
  }

  /**
   * Aktif oturumlar
   */
  async getActiveSessions(userId: string) {
    return this.prisma.userSession.findMany({
      where: { user_id: userId, deleted_at: null, expires_at: { gt: new Date() } },
      select: {
        id: true,
        device_name: true,
        device_type: true,
        ip_address: true,
        last_active_at: true,
        created_at: true,
      },
      orderBy: { last_active_at: 'desc' },
    });
  }

  // ============ Yardımcı Metodlar ============

  private async generateTokens(userId: string, email: string) {
    const payload = { sub: userId, email };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('JWT_SECRET'),
        expiresIn: this.configService.get<string>('JWT_EXPIRES_IN', '15m'),
      }),
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
        expiresIn: this.configService.get<string>('JWT_REFRESH_EXPIRES_IN', '7d'),
      }),
    ]);

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      token_type: 'Bearer',
      expires_in: 900, // 15 dakika (saniye)
    };
  }

  private async createSession(
    userId: string,
    tokens: any,
    meta: { device_name?: string; device_type?: string; ip_address?: string },
  ) {
    await this.prisma.userSession.create({
      data: {
        user_id: userId,
        device_name: meta.device_name || 'Bilinmeyen Cihaz',
        device_type: meta.device_type || 'unknown',
        ip_address: meta.ip_address,
        token_hash: this.hashToken(tokens.access_token),
        refresh_token_hash: this.hashToken(tokens.refresh_token),
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });
  }

  private hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  private sanitizeUser(user: any) {
    const { password_hash, pin_hash, ...sanitized } = user;
    return sanitized;
  }
}

