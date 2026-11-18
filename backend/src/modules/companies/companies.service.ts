/**
 * Companies Service - Firma Yönetimi İş Mantığı
 */
import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CompanyRole } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class CompaniesService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Yeni firma oluştur
   */
  async create(userId: string, data: {
    name: string;
    tax_office?: string;
    tax_number?: string;
    address?: string;
    city?: string;
    district?: string;
    phone?: string;
    email?: string;
    default_currency?: string;
  }) {
    return this.prisma.$transaction(async (tx) => {
      // Firma oluştur
      const company = await tx.company.create({
        data: {
          owner_id: userId,
          name: data.name,
          tax_office: data.tax_office,
          tax_number: data.tax_number,
          address: data.address,
          city: data.city,
          district: data.district,
          phone: data.phone,
          email: data.email,
          default_currency: data.default_currency || 'TRY',
        },
      });

      // Sahip olarak üye ekle
      await tx.companyUser.create({
        data: {
          company_id: company.id,
          user_id: userId,
          role: 'OWNER',
        },
      });

      // Varsayılan kasa oluştur
      await tx.cashAccount.create({
        data: {
          company_id: company.id,
          name: 'Ana Kasa',
          currency: data.default_currency || 'TRY',
        },
      });

      // Varsayılan kategoriler
      const defaultCategories = [
        { name: 'Kira', type: 'EXPENSE' as const },
        { name: 'Elektrik', type: 'EXPENSE' as const },
        { name: 'Su', type: 'EXPENSE' as const },
        { name: 'Doğalgaz', type: 'EXPENSE' as const },
        { name: 'Maaş', type: 'EXPENSE' as const },
        { name: 'Vergi', type: 'EXPENSE' as const },
        { name: 'Yemek', type: 'EXPENSE' as const },
        { name: 'Ulaşım', type: 'EXPENSE' as const },
        { name: 'Diğer Gider', type: 'EXPENSE' as const },
        { name: 'Satış Geliri', type: 'INCOME' as const },
        { name: 'Hizmet Geliri', type: 'INCOME' as const },
        { name: 'Diğer Gelir', type: 'INCOME' as const },
      ];

      for (const cat of defaultCategories) {
        await tx.category.create({
          data: { company_id: company.id, ...cat },
        });
      }

      // Varsayılan mesaj şablonları
      await tx.messageTemplate.create({
        data: {
          company_id: company.id,
          name: 'Borç Hatırlatma',
          type: 'REMINDER',
          subject: 'Ödeme Hatırlatması',
          body: 'Sayın {unvan}, {tarih} itibarıyla {tutar} bakiyeniz bulunmaktadır. Bilgilerinize sunarız.',
          is_default: true,
        },
      });

      return company;
    });
  }

  /**
   * Kullanıcının firmalarını listele
   */
  async findAllByUser(userId: string) {
    const memberships = await this.prisma.companyUser.findMany({
      where: { user_id: userId, deleted_at: null },
      include: {
        company: {
          select: {
            id: true,
            name: true,
            logo_url: true,
            default_currency: true,
            is_archived: true,
            created_at: true,
          },
        },
      },
    });

    if (memberships.length === 0) {
      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      const compName = user ? `${user.first_name} ${user.last_name} İşletmesi` : 'İşletmem';
      const newComp = await this.create(userId, { name: compName });
      return [{
        id: newComp.id,
        name: newComp.name,
        logo_url: newComp.logo_url,
        default_currency: newComp.default_currency,
        is_archived: newComp.is_archived,
        created_at: newComp.created_at,
        role: 'OWNER',
      }];
    }

    return memberships.map((m) => ({
      ...m.company,
      role: m.role,
    }));
  }

  /**
   * Firma detayı
   */
  async findById(companyId: string) {
    const company = await this.prisma.company.findUnique({
      where: { id: companyId, deleted_at: null },
      include: {
        company_users: {
          include: {
            user: {
              select: { id: true, email: true, first_name: true, last_name: true },
            },
          },
        },
      },
    });
    if (!company) throw new NotFoundException('Firma bulunamadı.');
    return company;
  }

  /**
   * Firma güncelle
   */
  async update(companyId: string, data: any) {
    return this.prisma.company.update({
      where: { id: companyId },
      data,
    });
  }

  /**
   * Kullanıcı davet et
   */
  async inviteUser(companyId: string, invitedById: string, email: string, role: CompanyRole) {
    // Zaten üye mi?
    const existingUser = await this.prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      const existingMembership = await this.prisma.companyUser.findUnique({
        where: { company_id_user_id: { company_id: companyId, user_id: existingUser.id } },
      });
      if (existingMembership) {
        throw new ConflictException('Bu kullanıcı zaten firmaya üye.');
      }
    }

    const token = uuidv4();
    const invitation = await this.prisma.invitation.create({
      data: {
        company_id: companyId,
        email: email.toLowerCase().trim(),
        role,
        token,
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 gün
        invited_by: invitedById,
      },
    });

    // TODO: Davet e-postası gönder
    return { message: `${email} adresine davet gönderildi.`, token };
  }

  /**
   * Daveti kabul et
   */
  async acceptInvitation(token: string, userId: string) {
    const invitation = await this.prisma.invitation.findUnique({ where: { token } });
    if (!invitation) throw new NotFoundException('Davet bulunamadı.');
    if (invitation.accepted_at) throw new BadRequestException('Bu davet zaten kabul edilmiş.');
    if (invitation.expires_at < new Date()) throw new BadRequestException('Davet süresi dolmuş.');

    await this.prisma.$transaction(async (tx) => {
      await tx.companyUser.create({
        data: {
          company_id: invitation.company_id,
          user_id: userId,
          role: invitation.role,
          invited_by: invitation.invited_by,
        },
      });

      await tx.invitation.update({
        where: { id: invitation.id },
        data: { accepted_at: new Date() },
      });
    });

    return { message: 'Firmaya başarıyla katıldınız.' };
  }

  /**
   * Firma devri
   */
  async transferOwnership(companyId: string, currentOwnerId: string, newOwnerId: string) {
    return this.prisma.$transaction(async (tx) => {
      // Eski sahibin rolünü güncelle
      await tx.companyUser.updateMany({
        where: { company_id: companyId, user_id: currentOwnerId },
        data: { role: 'VIEWER' },
      });

      // Yeni sahibi OWNER yap
      await tx.companyUser.upsert({
        where: { company_id_user_id: { company_id: companyId, user_id: newOwnerId } },
        update: { role: 'OWNER' },
        create: {
          company_id: companyId,
          user_id: newOwnerId,
          role: 'OWNER',
        },
      });

      // Company owner_id güncelle
      await tx.company.update({
        where: { id: companyId },
        data: { owner_id: newOwnerId },
      });

      return { message: 'Firma devri başarıyla tamamlandı.' };
    });
  }
}

