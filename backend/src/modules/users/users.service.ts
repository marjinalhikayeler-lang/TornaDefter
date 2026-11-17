/**
 * Users Service - Kullanıcı İş Mantığı
 */
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id, deleted_at: null },
      select: {
        id: true,
        email: true,
        phone: true,
        first_name: true,
        last_name: true,
        avatar_url: true,
        email_verified: true,
        phone_verified: true,
        is_active: true,
        biometric_enabled: true,
        lock_timeout: true,
        last_login_at: true,
        created_at: true,
      },
    });
    if (!user) throw new NotFoundException('Kullanıcı bulunamadı.');
    return user;
  }

  async updateProfile(userId: string, data: { first_name?: string; last_name?: string; phone?: string; avatar_url?: string }) {
    return this.prisma.user.update({
      where: { id: userId },
      data,
      select: {
        id: true,
        email: true,
        phone: true,
        first_name: true,
        last_name: true,
        avatar_url: true,
      },
    });
  }

  async requestDeletion(userId: string) {
    // KVKK: 30 gün sonra kalıcı silme
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        is_active: false,
        deleted_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    });
    return { message: 'Hesap silme talebiniz alındı. 30 gün içinde kalıcı olarak silinecektir. Bu sürede geri alabilirsiniz.' };
  }

  async cancelDeletion(userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { is_active: true, deleted_at: null },
    });
    return { message: 'Hesap silme talebi iptal edildi.' };
  }
}

