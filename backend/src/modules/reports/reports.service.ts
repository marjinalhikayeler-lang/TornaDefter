/**
 * Raporlar Service
 * OkLif tarzı: Cari bakiye, ekstre, borçlular/alacaklılar, yaşlandırma,
 * kasa/banka, gelir-gider, nakit akışı, çek/senet, personel, kâr/zarar
 */
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  /** 1. Cari bakiye raporu */
  async accountBalanceReport(companyId: string, filters: { account_type?: string; group_id?: string }) {
    const where: any = { company_id: companyId, deleted_at: null, is_archived: false };
    if (filters.account_type) where.account_type = filters.account_type;
    if (filters.group_id) where.group_id = filters.group_id;

    const accounts = await this.prisma.account.findMany({
      where,
      orderBy: { title: 'asc' },
      select: { id: true, code: true, title: true, account_type: true, opening_balance: true, opening_balance_direction: true },
    });

    const result = await Promise.all(accounts.map(async (acc) => {
      const debits = await this.prisma.transaction.aggregate({
        where: { account_id: acc.id, deleted_at: null, type: { in: ['SALE', 'PURCHASE', 'SALARY', 'ADVANCE'] } },
        _sum: { amount: true },
      });
      const credits = await this.prisma.transaction.aggregate({
        where: { account_id: acc.id, deleted_at: null, type: { in: ['COLLECTION', 'PAYMENT'] } },
        _sum: { amount: true },
      });

      let balance = acc.opening_balance_direction === 'DEBIT' ? acc.opening_balance : -acc.opening_balance;
      balance += (debits._sum.amount || 0) - (credits._sum.amount || 0);

      return {
        ...acc,
        total_debit: debits._sum.amount || 0,
        total_credit: credits._sum.amount || 0,
        balance,
      };
    }));

    const totalDebt = result.filter(r => r.balance > 0).reduce((s, r) => s + r.balance, 0);
    const totalCredit = result.filter(r => r.balance < 0).reduce((s, r) => s + Math.abs(r.balance), 0);

    return { data: result, meta: { total_debt: totalDebt, total_credit: totalCredit, net: totalDebt - totalCredit } };
  }

  /** 2. Cari ekstre */
  async accountStatement(companyId: string, accountId: string, startDate?: string, endDate?: string) {
    const where: any = { company_id: companyId, account_id: accountId, deleted_at: null };
    if (startDate || endDate) {
      where.date = {};
      if (startDate) where.date.gte = new Date(startDate);
      if (endDate) where.date.lte = new Date(endDate);
    }

    const account = await this.prisma.account.findUnique({ where: { id: accountId } });
    const transactions = await this.prisma.transaction.findMany({ where, orderBy: { date: 'asc' } });

    let runningBalance = account?.opening_balance_direction === 'DEBIT'
      ? (account?.opening_balance || 0)
      : -(account?.opening_balance || 0);

    const statement = transactions.map(t => {
      if (['SALE', 'PURCHASE', 'SALARY', 'ADVANCE'].includes(t.type)) {
        runningBalance += t.amount;
      } else {
        runningBalance -= t.amount;
      }
      return { ...t, running_balance: runningBalance };
    });

    return {
      account: { id: account?.id, title: account?.title, code: account?.code },
      opening_balance: account?.opening_balance || 0,
      closing_balance: runningBalance,
      transactions: statement,
    };
  }

  /** 3. Borçlular listesi */
  async debtorsReport(companyId: string) {
    return this.accountBalanceReport(companyId, { account_type: 'CUSTOMER' });
  }

  /** 4. Vadesi geçmiş alacaklar (yaşlandırma) */
  async agingReport(companyId: string) {
    const overdue = await this.prisma.transaction.findMany({
      where: {
        company_id: companyId,
        deleted_at: null,
        type: { in: ['SALE'] },
        due_date: { lt: new Date() },
      },
      include: { account: { select: { id: true, title: true } } },
      orderBy: { due_date: 'asc' },
    });

    const buckets = { '0_30': 0, '31_60': 0, '61_90': 0, '90_plus': 0 };
    const now = Date.now();

    overdue.forEach(t => {
      const days = Math.floor((now - (t.due_date?.getTime() || now)) / 86400000);
      if (days <= 30) buckets['0_30'] += t.amount;
      else if (days <= 60) buckets['31_60'] += t.amount;
      else if (days <= 90) buckets['61_90'] += t.amount;
      else buckets['90_plus'] += t.amount;
    });

    return { data: overdue, buckets, total: Object.values(buckets).reduce((a, b) => a + b, 0) };
  }

  /** 5. Kasa/Banka raporu */
  async cashBankReport(companyId: string) {
    const [cashAccounts, bankAccounts] = await Promise.all([
      this.prisma.cashAccount.findMany({ where: { company_id: companyId, deleted_at: null } }),
      this.prisma.bankAccount.findMany({ where: { company_id: companyId, deleted_at: null } }),
    ]);

    const totalCash = cashAccounts.reduce((s, a) => s + a.current_balance, 0);
    const totalBank = bankAccounts.reduce((s, a) => s + a.current_balance, 0);

    return {
      cash_accounts: cashAccounts,
      bank_accounts: bankAccounts,
      total_cash: totalCash,
      total_bank: totalBank,
      grand_total: totalCash + totalBank,
    };
  }

  /** 6. Gelir-Gider raporu */
  async incomeExpenseReport(companyId: string, startDate?: string, endDate?: string) {
    const where: any = { company_id: companyId, deleted_at: null };
    if (startDate || endDate) {
      where.date = {};
      if (startDate) where.date.gte = new Date(startDate);
      if (endDate) where.date.lte = new Date(endDate);
    }

    const records = await this.prisma.incomeExpense.findMany({
      where,
      include: { category: { select: { name: true, type: true } } },
      orderBy: { date: 'desc' },
    });

    const totalIncome = records.filter(r => r.type === 'INCOME').reduce((s, r) => s + r.amount, 0);
    const totalExpense = records.filter(r => r.type === 'EXPENSE').reduce((s, r) => s + r.amount, 0);

    return {
      data: records,
      total_income: totalIncome,
      total_expense: totalExpense,
      net_profit: totalIncome - totalExpense,
    };
  }

  /** 10. Kâr/Zarar özeti */
  async profitLossReport(companyId: string, startDate?: string, endDate?: string) {
    const ieReport = await this.incomeExpenseReport(companyId, startDate, endDate);
    return {
      income: ieReport.total_income,
      expense: ieReport.total_expense,
      profit: ieReport.net_profit,
      period: { start: startDate, end: endDate },
    };
  }
}
