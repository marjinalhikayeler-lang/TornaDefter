/**
 * Kasa Hesapları Service
 * Nakit kasa yönetimi, günlük özet, kasa sayımı
 */
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CashAccountsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(companyId: string, data: { name: string; currency?: string; opening_balance?: number }) {
    return this.prisma.cashAccount.create({
      data: {
        company_id: companyId,
        name: data.name,
        currency: data.currency || 'TRY',
        opening_balance: data.opening_balance || 0,
        current_balance: data.opening_balance || 0,
      },
    });
  }

  async findAll(companyId: string) {
    const accounts = await this.prisma.cashAccount.findMany({
      where: { company_id: companyId, deleted_at: null },
      orderBy: { name: 'asc' },
    });

    const total = accounts.reduce((sum, a) => sum + a.current_balance, 0);
    return { data: accounts, meta: { total_balance: total } };
  }

  async findById(companyId: string, id: string) {
    const account = await this.prisma.cashAccount.findFirst({
      where: { id, company_id: companyId, deleted_at: null },
    });
    if (!account) throw new NotFoundException('Kasa hesabı bulunamadı.');
    return account;
  }

  async update(companyId: string, id: string, data: any) {
    return this.prisma.cashAccount.update({ where: { id }, data });
  }

  /** Günlük kasa özeti */
  async dailySummary(companyId: string, cashAccountId: string, date: string) {
    const targetDate = new Date(date);
    const nextDate = new Date(targetDate);
    nextDate.setDate(nextDate.getDate() + 1);

    const transactions = await this.prisma.transaction.findMany({
      where: {
        company_id: companyId,
        cash_account_id: cashAccountId,
        date: { gte: targetDate, lt: nextDate },
        deleted_at: null,
      },
    });

    const totalIn = transactions
      .filter((t) => ['COLLECTION'].includes(t.type))
      .reduce((sum, t) => sum + t.amount, 0);

    const totalOut = transactions
      .filter((t) => ['PAYMENT', 'SALARY', 'ADVANCE'].includes(t.type))
      .reduce((sum, t) => sum + t.amount, 0);

    const account = await this.prisma.cashAccount.findUnique({ where: { id: cashAccountId } });

    return {
      date,
      opening_balance: (account?.current_balance || 0) - totalIn + totalOut,
      total_in: totalIn,
      total_out: totalOut,
      closing_balance: account?.current_balance || 0,
      transaction_count: transactions.length,
    };
  }

  /** Kasa sayımı */
  async cashCount(companyId: string, cashAccountId: string, userId: string, countedAmount: number) {
    const account = await this.prisma.cashAccount.findFirst({
      where: { id: cashAccountId, company_id: companyId },
    });
    if (!account) throw new NotFoundException('Kasa bulunamadı.');

    const difference = countedAmount - account.current_balance;
    if (difference === 0) return { message: 'Kasa bakiyesi doğru, fark yok.', difference: 0 };

    // Fark kaydı oluştur
    await this.prisma.cashAccount.update({
      where: { id: cashAccountId },
      data: { current_balance: countedAmount },
    });

    await this.prisma.auditLog.create({
      data: {
        company_id: companyId,
        user_id: userId,
        action: 'UPDATE',
        entity_type: 'cash_count',
        entity_id: cashAccountId,
        old_values: { balance: account.current_balance },
        new_values: { balance: countedAmount, difference },
      },
    });

    return {
      message: difference > 0 ? 'Kasa fazlası tespit edildi.' : 'Kasa açığı tespit edildi.',
      difference,
      old_balance: account.current_balance,
      new_balance: countedAmount,
    };
  }
}
