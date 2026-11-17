import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class SubscriptionsService {
  constructor(private readonly prisma: PrismaService) {}

  // TornaDefter tamamen ücretsiz - tüm özellikler sınırsız
  async getActivePlan(userId: string) {
    const subscription = await this.prisma.subscription.findFirst({
      where: { user_id: userId, deleted_at: null },
      include: { plan: true },
      orderBy: { created_at: 'desc' },
    });

    if (!subscription) {
      // Ücretsiz plan otomatik ata
      const freePlan = await this.prisma.plan.findFirst({
        where: { slug: 'ucretsiz', deleted_at: null },
      });

      if (freePlan) {
        const newSub = await this.prisma.subscription.create({
          data: {
            user_id: userId,
            plan_id: freePlan.id,
            status: 'ACTIVE',
          },
        });
        return { ...newSub, plan: freePlan };
      }
    }

    return subscription;
  }

  async getPlanInfo() {
    // Tek plan: Ücretsiz, sınırsız
    return {
      name: 'Ücretsiz',
      slug: 'ucretsiz',
      price: 0,
      features: [
        'Sınırsız cari hesap',
        'Sınırsız işlem',
        'Sınırsız firma',
        'Sınırsız kullanıcı',
        'Tüm raporlar',
        'PDF/Excel dışa aktarma',
        'Çek/senet takibi',
        'Kasa ve banka yönetimi',
        'Otomatik yedekleme',
        'Push bildirimler',
        'WhatsApp paylaşım',
        'Destek',
      ],
      limits: {
        maxAccounts: -1, // Sınırsız
        maxUsers: -1,
        maxCompanies: -1,
        storageLimit: -1,
      },
    };
  }
}
