import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationType } from '@prisma/client';

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(userId: string, filters?: {
    companyId?: string;
    isRead?: boolean;
    page?: number;
    limit?: number;
  }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 50;
    const where: any = { user_id: userId, deleted_at: null };
    if (filters?.companyId) where.company_id = filters.companyId;
    if (filters?.isRead !== undefined) where.is_read = filters.isRead;

    const [items, total, unreadCount] = await this.prisma.$transaction([
      this.prisma.notification.findMany({
        where,
        orderBy: { created_at: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.notification.count({ where }),
      this.prisma.notification.count({ where: { user_id: userId, is_read: false, deleted_at: null } }),
    ]);

    return { items, total, unreadCount, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async markAsRead(userId: string, id: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id, user_id: userId, deleted_at: null },
    });
    if (!notification) throw new NotFoundException('Bildirim bulunamadı');

    return this.prisma.notification.update({
      where: { id },
      data: { is_read: true, read_at: new Date() },
    });
  }

  async markAllAsRead(userId: string, companyId?: string) {
    const where: any = { user_id: userId, is_read: false, deleted_at: null };
    if (companyId) where.company_id = companyId;

    return this.prisma.notification.updateMany({
      where,
      data: { is_read: true, read_at: new Date() },
    });
  }

  async remove(userId: string, id: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id, user_id: userId, deleted_at: null },
    });
    if (!notification) throw new NotFoundException('Bildirim bulunamadı');

    return this.prisma.notification.update({
      where: { id },
      data: { deleted_at: new Date() },
    });
  }

  async clearAll(userId: string) {
    return this.prisma.notification.updateMany({
      where: { user_id: userId, deleted_at: null },
      data: { deleted_at: new Date() },
    });
  }

  // Bildirim oluşturma (iç kullanım)
  async createNotification(data: {
    userId: string;
    companyId?: string;
    type: NotificationType;
    title: string;
    body: string;
    data?: any;
  }) {
    return this.prisma.notification.create({
      data: {
        user_id: data.userId,
        company_id: data.companyId || null,
        type: data.type,
        title: data.title,
        body: data.body,
        data: data.data || null,
      },
    });
  }

  // Vade hatırlatmalarını kontrol et ve bildirim oluştur
  async checkDueReminders() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Vadesi yaklaşan/geçen işlemler
    const dueTransactions = await this.prisma.transaction.findMany({
      where: {
        due_date: { lte: tomorrow },
        deleted_at: null,
        is_reconciled: false,
      },
      include: {
        account: { select: { title: true } },
        company: { select: { company_users: { select: { user_id: true } } } },
      },
    });

    for (const tx of dueTransactions) {
      const isOverdue = new Date(tx.due_date!) < today;
      for (const cu of tx.company.company_users) {
        await this.createNotification({
          userId: cu.user_id,
          companyId: tx.company_id,
          type: 'PAYMENT_DUE',
          title: isOverdue ? 'Vadesi Geçmiş İşlem' : 'Vade Hatırlatması',
          body: `${tx.account.title} - ${(tx.amount / 100).toLocaleString('tr-TR')} TL`,
          data: { transactionId: tx.id, accountId: tx.account_id },
        });
      }
    }

    // Vadesi yaklaşan çek/senetler
    const dueCheques = await this.prisma.chequeNote.findMany({
      where: {
        due_date: { lte: tomorrow },
        deleted_at: null,
        status: { in: ['IN_PORTFOLIO', 'DEPOSITED'] },
      },
      include: {
        company: { select: { company_users: { select: { user_id: true } } } },
      },
    });

    for (const cn of dueCheques) {
      const typeName = cn.type === 'CHEQUE' ? 'Çek' : 'Senet';
      for (const cu of cn.company.company_users) {
        await this.createNotification({
          userId: cu.user_id,
          companyId: cn.company_id,
          type: 'CHEQUE_DUE',
          title: `${typeName} Vade Hatırlatması`,
          body: `${cn.cheque_number || typeName} - ${(cn.amount / 100).toLocaleString('tr-TR')} TL`,
          data: { chequeNoteId: cn.id },
        });
      }
    }

    return { processedTransactions: dueTransactions.length, processedCheques: dueCheques.length };
  }

  // Bildirim tercihleri
  async getSettings(userId: string, companyId?: string) {
    return this.prisma.notificationSetting.findMany({
      where: { user_id: userId, ...(companyId ? { company_id: companyId } : {}), deleted_at: null },
    });
  }

  async updateSetting(userId: string, data: {
    companyId?: string;
    notificationType: NotificationType;
    isEnabled: boolean;
    preferredTime?: string;
    preferredChannels?: string[];
  }) {
    const existing = await this.prisma.notificationSetting.findFirst({
      where: {
        user_id: userId,
        company_id: data.companyId || null,
        notification_type: data.notificationType,
      },
    });

    if (existing) {
      return this.prisma.notificationSetting.update({
        where: { id: existing.id },
        data: {
          is_enabled: data.isEnabled,
          preferred_time: data.preferredTime || undefined,
          preferred_channels: data.preferredChannels || undefined,
        },
      });
    }

    return this.prisma.notificationSetting.create({
      data: {
        user_id: userId,
        company_id: data.companyId || null,
        notification_type: data.notificationType,
        is_enabled: data.isEnabled,
        preferred_time: data.preferredTime || undefined,
        preferred_channels: data.preferredChannels || undefined,
      },
    });
  }
}
