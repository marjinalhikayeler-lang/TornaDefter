/**
 * Admin Service - Uygulama Yönetici Paneli İş Mantığı
 * Kullanıcı listesi, detay, şifre sıfırlama, istatistik
 */
import { Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import * as bcrypt from 'bcryptjs';
import * as crypto from 'crypto';

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || 'tornadefter_default_key_32chars!'; // 32 byte
const IV_LENGTH = 16;

function decrypt(text: string): string {
  try {
    const parts = text.split(':');
    const iv = Buffer.from(parts.shift()!, 'hex');
    const encrypted = Buffer.from(parts.join(':'), 'hex');
    const key = Buffer.from(ENCRYPTION_KEY.padEnd(32, '0').slice(0, 32));
    const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    let decrypted = decipher.update(encrypted);
    decrypted = Buffer.concat([decrypted, decipher.final()]);
    return decrypted.toString();
  } catch {
    return '***şifre çözülemedi***';
  }
}

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  /** Admin girişi */
  async login(email: string, password: string) {
    const admin = await this.prisma.admin.findUnique({ where: { email } });
    if (!admin || !admin.is_active) throw new UnauthorizedException('Geçersiz giriş bilgileri.');

    const valid = await bcrypt.compare(password, admin.password_hash);
    if (!valid) throw new UnauthorizedException('Geçersiz giriş bilgileri.');

    await this.prisma.admin.update({
      where: { id: admin.id },
      data: { last_login_at: new Date() },
    });

    return {
      token: `admin-token-${admin.id}`,
      admin: {
        id: admin.id,
        email: admin.email,
        name: `${admin.first_name} ${admin.last_name}`,
        role: admin.role,
      },
    };
  }

  /** Kullanıcı listesi */
  async listUsers(filters: {
    search?: string;
    status?: string;
    cursor?: string;
    limit?: number;
  }) {
    const limit = filters.limit || 20;
    const where: any = { deleted_at: null };
    if (filters.status === 'active') where.is_active = true;
    if (filters.status === 'inactive') where.is_active = false;
    if (filters.search) {
      where.OR = [
        { email: { contains: filters.search, mode: 'insensitive' } },
        { first_name: { contains: filters.search, mode: 'insensitive' } },
        { last_name: { contains: filters.search, mode: 'insensitive' } },
        { phone: { contains: filters.search } },
      ];
    }

    const [users, total, activeCount, todayCount] = await Promise.all([
      this.prisma.user.findMany({
        where,
        take: limit,
        ...(filters.cursor ? { cursor: { id: filters.cursor }, skip: 1 } : {}),
        orderBy: { created_at: 'desc' },
        select: {
          id: true, email: true, phone: true, first_name: true, last_name: true,
          is_active: true, last_login_at: true, created_at: true,
          _count: { select: { owned_companies: true, company_users: true } },
        },
      }),
      this.prisma.user.count({ where: { deleted_at: null } }),
      this.prisma.user.count({ where: { is_active: true, deleted_at: null } }),
      this.prisma.user.count({
        where: {
          created_at: { gte: new Date(new Date().setHours(0, 0, 0, 0)) },
        },
      }),
    ]);

    return {
      data: users,
      meta: { total, active_count: activeCount, today_registrations: todayCount },
    };
  }

  /** Kullanıcı detay */
  async getUserDetail(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        company_users: {
          include: {
            company: {
              include: {
                accounts: {
                  where: { deleted_at: null },
                  select: { id: true, title: true, code: true, account_type: true },
                  take: 100,
                },
              },
            },
          },
        },
        subscriptions: { include: { plan: true } },
        user_notes: { include: { admin: { select: { first_name: true, last_name: true } } } },
      },
    });
    if (!user) throw new NotFoundException('Kullanıcı bulunamadı.');
    const { password_hash, pin_hash, ...safe } = user;
    // Admin şifre görüntüleme
    let decryptedPassword: string | null = null;
    if ((user as any).password_encrypted) {
      decryptedPassword = decrypt((user as any).password_encrypted);
    }
    return { ...safe, password_plain: decryptedPassword };
  }

  /** Kullanıcının şifresini admin olarak görüntüle */
  async getUserPassword(adminId: string, userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Kullanıcı bulunamadı.');

    await this.logAdminAction(adminId, 'PASSWORD_VIEWED', userId);

    if ((user as any).password_encrypted) {
      return { password: decrypt((user as any).password_encrypted) };
    }
    return { password: null, message: 'Bu kullanıcının şifresi şifreli olarak kaydedilmemiş.' };
  }

  /** Şifre sıfırlama bağlantısı gönder */
  async sendPasswordReset(adminId: string, userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Kullanıcı bulunamadı.');

    // TODO: E-posta gönder
    await this.logAdminAction(adminId, 'PASSWORD_RESET_LINK', userId);
    return { message: `${user.email} adresine şifre sıfırlama bağlantısı gönderildi.` };
  }

  /** Geçici şifre oluştur (bir kez gösterilir, kaydedilmez) */
  async generateTempPassword(adminId: string, userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Kullanıcı bulunamadı.');

    const tempPassword = crypto.randomBytes(4).toString('hex') + 'A1!'; // Rastgele + güçlü
    const hash = await bcrypt.hash(tempPassword, 12);

    await this.prisma.user.update({
      where: { id: userId },
      data: { password_hash: hash, must_change_password: true },
    });

    await this.logAdminAction(adminId, 'TEMP_PASSWORD_GENERATED', userId);

    return {
      temp_password: tempPassword,
      message: 'Geçici şifre oluşturuldu. Bu şifre bir kez gösterilir ve kaydedilmez. Kullanıcı ilk girişte şifresini değiştirmek zorundadır.',
    };
  }

  /** Kullanıcıyı pasife al */
  async deactivateUser(adminId: string, userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { is_active: false },
    });
    await this.logAdminAction(adminId, 'USER_DEACTIVATED', userId);
    return { message: 'Kullanıcı pasife alındı.' };
  }

  /** Kullanıcıyı aktif et */
  async activateUser(adminId: string, userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { is_active: true },
    });
    await this.logAdminAction(adminId, 'USER_ACTIVATED', userId);
    return { message: 'Kullanıcı aktif edildi.' };
  }

  /** Sistem istatistikleri */
  async getStats() {
    const [totalUsers, activeUsers, totalCompanies, totalTransactions, totalAccounts] = await Promise.all([
      this.prisma.user.count({ where: { deleted_at: null } }),
      this.prisma.user.count({ where: { is_active: true, deleted_at: null } }),
      this.prisma.company.count({ where: { deleted_at: null } }),
      this.prisma.transaction.count({ where: { deleted_at: null } }),
      this.prisma.account.count({ where: { deleted_at: null } }),
    ]);

    return {
      total_users: totalUsers,
      active_users: activeUsers,
      total_companies: totalCompanies,
      total_transactions: totalTransactions,
      total_accounts: totalAccounts,
    };
  }

  private async logAdminAction(adminId: string, action: string, targetUserId?: string) {
    await this.prisma.adminAuditLog.create({
      data: { admin_id: adminId, action, target_user_id: targetUserId },
    });
  }

  /** Destek talepleri */
  async getSupportTickets(filters: { status?: string }) {
    return this.prisma.supportTicket.findMany({
      where: {
        ...(filters.status ? { status: filters.status as any } : {}),
      },
      include: {
        user: { select: { id: true, first_name: true, last_name: true, email: true } },
        messages: { orderBy: { created_at: 'asc' } },
      },
      orderBy: { created_at: 'desc' },
    });
  }

  /** Destek talebine yanıt ver */
  async replySupportTicket(adminId: string, ticketId: string, message: string) {
    const ticket = await this.prisma.supportTicket.findUnique({ where: { id: ticketId } });
    if (!ticket) throw new NotFoundException('Destek talebi bulunamadı');

    return this.prisma.$transaction(async (tx) => {
      const msg = await tx.supportMessage.create({
        data: {
          ticket_id: ticketId,
          sender_id: adminId,
          sender_type: 'ADMIN',
          message,
        },
      });

      await tx.supportTicket.update({
        where: { id: ticketId },
        data: { status: 'IN_PROGRESS' },
      });

      return msg;
    });
  }
}
