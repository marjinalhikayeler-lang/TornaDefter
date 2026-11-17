import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class BankAccountsService {
  constructor(private readonly prisma: PrismaService) { }

  async create(companyId: string, data: {
    name: string;
    bankName?: string;
    iban?: string;
    currency?: string;
    openingBalance?: number;
  }) {
    return this.prisma.bankAccount.create({
      data: {
        company_id: companyId,
        name: data.name,
        bank_name: data.bankName || null,
        iban_encrypted: data.iban || null,
        currency: data.currency || 'TRY',
        opening_balance: data.openingBalance || 0,
        current_balance: data.openingBalance || 0,
      },
    });
  }

  async findAll(companyId: string, includeInactive = false) {
    return this.prisma.bankAccount.findMany({
      where: {
        company_id: companyId,
        deleted_at: null,
        ...(includeInactive ? {} : { is_active: true }),
      },
      orderBy: { name: 'asc' },
    });
  }

  async findOne(companyId: string, id: string) {
    const account = await this.prisma.bankAccount.findFirst({
      where: { id, company_id: companyId, deleted_at: null },
    });
    if (!account) throw new NotFoundException('Banka hesabı bulunamadı');
    return account;
  }

  async update(companyId: string, id: string, data: {
    name?: string;
    bankName?: string;
    iban?: string;
    currency?: string;
    isActive?: boolean;
  }) {
    await this.findOne(companyId, id);
    return this.prisma.bankAccount.update({
      where: { id },
      data: {
        ...(data.name !== undefined && { name: data.name }),
        ...(data.bankName !== undefined && { bank_name: data.bankName }),
        ...(data.iban !== undefined && { iban_encrypted: data.iban }),
        ...(data.currency !== undefined && { currency: data.currency }),
        ...(data.isActive !== undefined && { is_active: data.isActive }),
      },
    });
  }

  async remove(companyId: string, id: string) {
    await this.findOne(companyId, id);
    return this.prisma.bankAccount.update({
      where: { id },
      data: { deleted_at: new Date() },
    });
  }

  async getTransactions(companyId: string, id: string, filters?: {
    startDate?: string;
    endDate?: string;
    page?: number;
    limit?: number;
  }) {
    await this.findOne(companyId, id);
    const page = filters?.page || 1;
    const limit = filters?.limit || 50;
    const where: any = {
      company_id: companyId,
      bank_account_id: id,
      deleted_at: null,
    };
    if (filters?.startDate) where.date = { ...where.date, gte: new Date(filters.startDate) };
    if (filters?.endDate) where.date = { ...where.date, lte: new Date(filters.endDate) };

    const [items, total] = await this.prisma.$transaction([
      this.prisma.transaction.findMany({
        where,
        orderBy: { date: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: { account: { select: { title: true, code: true } } },
      }),
      this.prisma.transaction.count({ where }),
    ]);
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async getSummary(companyId: string) {
    const accounts = await this.prisma.bankAccount.findMany({
      where: { company_id: companyId, deleted_at: null, is_active: true },
    });
    const totalBalance = accounts.reduce((sum, a) => sum + a.current_balance, 0);
    return { accounts, totalBalance };
  }
}
