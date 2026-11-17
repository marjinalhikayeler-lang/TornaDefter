import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { TransferAccountType } from '@prisma/client';

@Injectable()
export class TransfersService {
  constructor(private readonly prisma: PrismaService) {}

  async create(companyId: string, userId: string, data: {
    fromAccountType: TransferAccountType;
    fromAccountId: string;
    toAccountType: TransferAccountType;
    toAccountId: string;
    amount: number;
    currency?: string;
    date: string;
    description?: string;
  }) {
    if (data.amount <= 0) throw new BadRequestException('Tutar sıfırdan büyük olmalıdır');
    if (data.fromAccountId === data.toAccountId && data.fromAccountType === data.toAccountType) {
      throw new BadRequestException('Kaynak ve hedef hesap aynı olamaz');
    }

    return this.prisma.$transaction(async (tx) => {
      // Kaynak hesaptan düş
      if (data.fromAccountType === 'CASH') {
        const acc = await tx.cashAccount.findFirst({ where: { id: data.fromAccountId, company_id: companyId, deleted_at: null } });
        if (!acc) throw new NotFoundException('Kaynak kasa hesabı bulunamadı');
        await tx.cashAccount.update({ where: { id: data.fromAccountId }, data: { current_balance: { decrement: data.amount } } });
      } else {
        const acc = await tx.bankAccount.findFirst({ where: { id: data.fromAccountId, company_id: companyId, deleted_at: null } });
        if (!acc) throw new NotFoundException('Kaynak banka hesabı bulunamadı');
        await tx.bankAccount.update({ where: { id: data.fromAccountId }, data: { current_balance: { decrement: data.amount } } });
      }

      // Hedef hesaba ekle
      if (data.toAccountType === 'CASH') {
        const acc = await tx.cashAccount.findFirst({ where: { id: data.toAccountId, company_id: companyId, deleted_at: null } });
        if (!acc) throw new NotFoundException('Hedef kasa hesabı bulunamadı');
        await tx.cashAccount.update({ where: { id: data.toAccountId }, data: { current_balance: { increment: data.amount } } });
      } else {
        const acc = await tx.bankAccount.findFirst({ where: { id: data.toAccountId, company_id: companyId, deleted_at: null } });
        if (!acc) throw new NotFoundException('Hedef banka hesabı bulunamadı');
        await tx.bankAccount.update({ where: { id: data.toAccountId }, data: { current_balance: { increment: data.amount } } });
      }

      // Transfer kaydı oluştur
      return tx.transfer.create({
        data: {
          company_id: companyId,
          from_account_type: data.fromAccountType,
          from_account_id: data.fromAccountId,
          to_account_type: data.toAccountType,
          to_account_id: data.toAccountId,
          amount: data.amount,
          currency: data.currency || 'TRY',
          date: new Date(data.date),
          description: data.description || null,
          created_by: userId,
        },
      });
    });
  }

  async findAll(companyId: string, filters?: { startDate?: string; endDate?: string; page?: number; limit?: number }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 50;
    const where: any = { company_id: companyId, deleted_at: null };
    if (filters?.startDate) where.date = { ...where.date, gte: new Date(filters.startDate) };
    if (filters?.endDate) where.date = { ...where.date, lte: new Date(filters.endDate) };

    const [items, total] = await this.prisma.$transaction([
      this.prisma.transfer.findMany({ where, orderBy: { date: 'desc' }, skip: (page - 1) * limit, take: limit }),
      this.prisma.transfer.count({ where }),
    ]);
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async findOne(companyId: string, id: string) {
    const transfer = await this.prisma.transfer.findFirst({ where: { id, company_id: companyId, deleted_at: null } });
    if (!transfer) throw new NotFoundException('Transfer bulunamadı');
    return transfer;
  }

  async remove(companyId: string, id: string) {
    const transfer = await this.findOne(companyId, id);
    return this.prisma.$transaction(async (tx) => {
      // Kaynak hesaba geri ekle
      if (transfer.from_account_type === 'CASH') {
        await tx.cashAccount.update({ where: { id: transfer.from_account_id }, data: { current_balance: { increment: transfer.amount } } });
      } else {
        await tx.bankAccount.update({ where: { id: transfer.from_account_id }, data: { current_balance: { increment: transfer.amount } } });
      }
      // Hedef hesaptan düş
      if (transfer.to_account_type === 'CASH') {
        await tx.cashAccount.update({ where: { id: transfer.to_account_id }, data: { current_balance: { decrement: transfer.amount } } });
      } else {
        await tx.bankAccount.update({ where: { id: transfer.to_account_id }, data: { current_balance: { decrement: transfer.amount } } });
      }
      return tx.transfer.update({ where: { id }, data: { deleted_at: new Date() } });
    });
  }
}
