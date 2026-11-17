import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { IncomeExpenseType } from '@prisma/client';

@Injectable()
export class IncomeExpensesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(companyId: string, userId: string, data: any) {
    const type = data.type as IncomeExpenseType;
    const amount = Number(data.amount) || 0;
    const rawDate = data.date;
    const date = rawDate ? new Date(rawDate) : new Date();
    const description = data.description || null;
    const documentNumber = data.documentNumber || data.document_number || null;
    const cashAccountId = data.cashAccountId || data.cash_account_id || null;
    const bankAccountId = data.bankAccountId || data.bank_account_id || null;
    const categoryId = data.categoryId || data.category_id || null;

    return this.prisma.$transaction(async (tx) => {
      const record = await tx.incomeExpense.create({
        data: {
          company_id: companyId,
          type,
          category_id: categoryId,
          cash_account_id: cashAccountId,
          bank_account_id: bankAccountId,
          amount,
          currency: data.currency || 'TRY',
          date: !isNaN(date.getTime()) ? date : new Date(),
          description,
          document_number: documentNumber,
          created_by: userId,
        },
      });

      // Kasa/banka bakiyesini güncelle
      const balanceChange = type === 'INCOME' ? amount : -amount;
      if (cashAccountId) {
        await tx.cashAccount.update({
          where: { id: cashAccountId },
          data: { current_balance: { increment: balanceChange } },
        });
      }
      if (bankAccountId) {
        await tx.bankAccount.update({
          where: { id: bankAccountId },
          data: { current_balance: { increment: balanceChange } },
        });
      }

      return record;
    });
  }

  async findAll(companyId: string, filters?: {
    type?: IncomeExpenseType;
    categoryId?: string;
    startDate?: string;
    endDate?: string;
    page?: number;
    limit?: number;
  }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 50;
    const where: any = { company_id: companyId, deleted_at: null };
    if (filters?.type) where.type = filters.type;
    if (filters?.categoryId) where.category_id = filters.categoryId;
    if (filters?.startDate || filters?.endDate) {
      where.date = {};
      if (filters?.startDate) where.date.gte = new Date(filters.startDate);
      if (filters?.endDate) where.date.lte = new Date(filters.endDate);
    }

    const [items, total] = await this.prisma.$transaction([
      this.prisma.incomeExpense.findMany({
        where,
        orderBy: { date: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: {
          category: { select: { name: true, type: true } },
          cash_account: { select: { name: true } },
          bank_account: { select: { name: true } },
        },
      }),
      this.prisma.incomeExpense.count({ where }),
    ]);

    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async findOne(companyId: string, id: string) {
    const record = await this.prisma.incomeExpense.findFirst({
      where: { id, company_id: companyId, deleted_at: null },
      include: {
        category: true,
        cash_account: true,
        bank_account: true,
      },
    });
    if (!record) throw new NotFoundException('Gelir/Gider kaydı bulunamadı');
    return record;
  }

  async update(companyId: string, id: string, userId: string, data: {
    categoryId?: string;
    amount?: number;
    description?: string;
    date?: string;
    documentNumber?: string;
  }) {
    const existing = await this.findOne(companyId, id);
    return this.prisma.$transaction(async (tx) => {
      // Eski bakiye etkisini geri al
      if (data.amount !== undefined && data.amount !== existing.amount) {
        const oldChange = existing.type === 'INCOME' ? existing.amount : -existing.amount;
        const newChange = existing.type === 'INCOME' ? data.amount : -data.amount;
        const diff = newChange - oldChange;

        if (existing.cash_account_id) {
          await tx.cashAccount.update({
            where: { id: existing.cash_account_id },
            data: { current_balance: { increment: diff } },
          });
        }
        if (existing.bank_account_id) {
          await tx.bankAccount.update({
            where: { id: existing.bank_account_id },
            data: { current_balance: { increment: diff } },
          });
        }
      }

      return tx.incomeExpense.update({
        where: { id },
        data: {
          ...(data.categoryId !== undefined && { category_id: data.categoryId }),
          ...(data.amount !== undefined && { amount: data.amount }),
          ...(data.description !== undefined && { description: data.description }),
          ...(data.date !== undefined && { date: new Date(data.date) }),
          ...(data.documentNumber !== undefined && { document_number: data.documentNumber }),
        },
      });
    });
  }

  async remove(companyId: string, id: string) {
    const record = await this.findOne(companyId, id);
    return this.prisma.$transaction(async (tx) => {
      // Bakiye etkisini geri al
      const balanceRevert = record.type === 'INCOME' ? -record.amount : record.amount;
      if (record.cash_account_id) {
        await tx.cashAccount.update({
          where: { id: record.cash_account_id },
          data: { current_balance: { increment: balanceRevert } },
        });
      }
      if (record.bank_account_id) {
        await tx.bankAccount.update({
          where: { id: record.bank_account_id },
          data: { current_balance: { increment: balanceRevert } },
        });
      }
      return tx.incomeExpense.update({ where: { id }, data: { deleted_at: new Date() } });
    });
  }

  async getSummary(companyId: string, startDate?: string, endDate?: string) {
    const where: any = { company_id: companyId, deleted_at: null };
    if (startDate || endDate) {
      where.date = {};
      if (startDate) where.date.gte = new Date(startDate);
      if (endDate) where.date.lte = new Date(endDate);
    }

    const incomes = await this.prisma.incomeExpense.aggregate({
      where: { ...where, type: 'INCOME' },
      _sum: { amount: true },
      _count: true,
    });

    const expenses = await this.prisma.incomeExpense.aggregate({
      where: { ...where, type: 'EXPENSE' },
      _sum: { amount: true },
      _count: true,
    });

    return {
      totalIncome: incomes._sum.amount || 0,
      incomeCount: incomes._count,
      totalExpense: expenses._sum.amount || 0,
      expenseCount: expenses._count,
      netProfit: (incomes._sum.amount || 0) - (expenses._sum.amount || 0),
    };
  }
}
