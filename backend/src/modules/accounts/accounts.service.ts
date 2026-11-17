/**
 * Accounts Service - Cari Hesap İş Mantığı
 * OkLif tarzı: müşteri, tedarikçi, personel, ortak takibi
 */
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AccountType, BalanceDirection } from '@prisma/client';

@Injectable()
export class AccountsService {
  private readonly logger = new Logger(AccountsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Yeni cari oluştur
   */
  async create(companyId: string, data: {
    title: string;
    account_type: AccountType;
    authorized_person?: string;
    phones?: any;
    email?: string;
    address?: string;
    city?: string;
    district?: string;
    tax_office?: string;
    tax_number?: string;
    identity_number?: string;
    notes?: string;
    risk_limit?: number;
    default_due_days?: number;
    currency?: string;
    opening_balance?: number;
    opening_balance_direction?: BalanceDirection;
    opening_date?: string;
    group_id?: string;
  }) {
    const accountType = data.account_type || (data as any).accountType || 'CUSTOMER';
    const taxNumber = data.tax_number || (data as any).taxNumber;
    const taxOffice = data.tax_office || (data as any).taxOffice;
    const openingBalance = data.opening_balance ?? (data as any).openingBalance ?? 0;
    const openingBalanceDirection = data.opening_balance_direction || (data as any).openingBalanceDirection || 'DEBIT';

    // Mükerrer kontrolü (telefon veya vergi no)
    if (taxNumber) {
      const existing = await this.prisma.account.findFirst({
        where: { company_id: companyId, tax_number: taxNumber, deleted_at: null },
      });
      if (existing) {
        this.logger.warn(`Mükerrer vergi no uyarısı: ${taxNumber}`);
      }
    }

    // Otomatik cari kodu üret
    const code = await this.generateCode(companyId, accountType);

    return this.prisma.account.create({
      data: {
        company_id: companyId,
        code,
        title: data.title.trim(),
        account_type: accountType,
        authorized_person: data.authorized_person,
        phones: data.phones || ((data as any).phone ? [(data as any).phone] : undefined),
        email: data.email,
        address: data.address,
        city: data.city,
        district: data.district,
        tax_office: taxOffice,
        tax_number: taxNumber,
        identity_number: data.identity_number,
        notes: data.notes,
        risk_limit: data.risk_limit,
        default_due_days: data.default_due_days,
        currency: data.currency || 'TRY',
        opening_balance: openingBalance,
        opening_balance_direction: openingBalanceDirection,
        opening_date: data.opening_date ? new Date(data.opening_date) : null,
        group_id: data.group_id,
      },
    });
  }

  /**
   * Cari listesi (OkLif tarzı - bakiyeli liste)
   */
  async findAll(companyId: string, filters: {
    search?: string;
    account_type?: AccountType;
    is_archived?: boolean;
    has_debt?: boolean;
    has_credit?: boolean;
    group_id?: string;
    sort_by?: string;
    sort_order?: 'asc' | 'desc';
    cursor?: string;
    limit?: number;
  }) {
    const limit = filters.limit || 20;
    const where: any = {
      company_id: companyId,
      deleted_at: null,
      is_archived: filters.is_archived || false,
    };

    if (filters.account_type) where.account_type = filters.account_type;
    if (filters.group_id) where.group_id = filters.group_id;

    if (filters.search) {
      where.OR = [
        { title: { contains: filters.search, mode: 'insensitive' } },
        { code: { contains: filters.search, mode: 'insensitive' } },
        { tax_number: { contains: filters.search } },
        { email: { contains: filters.search, mode: 'insensitive' } },
      ];
    }

    const accounts = await this.prisma.account.findMany({
      where,
      take: limit + 1,
      ...(filters.cursor ? { cursor: { id: filters.cursor }, skip: 1 } : {}),
      orderBy: { [filters.sort_by || 'title']: filters.sort_order || 'asc' },
      select: {
        id: true,
        code: true,
        title: true,
        account_type: true,
        phones: true,
        email: true,
        opening_balance: true,
        opening_balance_direction: true,
        risk_limit: true,
        is_archived: true,
        created_at: true,
        updated_at: true,
      },
    });

    const hasMore = accounts.length > limit;
    const data = hasMore ? accounts.slice(0, limit) : accounts;

    // Her cari için bakiye hesapla
    const accountsWithBalance = await Promise.all(
      data.map(async (account) => {
        const balance = await this.calculateBalance(account.id, account.opening_balance, account.opening_balance_direction);
        const lastTransaction = await this.prisma.transaction.findFirst({
          where: { account_id: account.id, deleted_at: null },
          orderBy: { date: 'desc' },
          select: { date: true },
        });

        return {
          ...account,
          current_balance: balance,
          last_transaction_date: lastTransaction?.date || null,
        };
      }),
    );

    // Toplam borç ve alacak
    const totals = accountsWithBalance.reduce(
      (acc, a) => {
        if (a.current_balance > 0) acc.total_debt += a.current_balance;
        else acc.total_credit += Math.abs(a.current_balance);
        return acc;
      },
      { total_debt: 0, total_credit: 0 },
    );

    return {
      data: accountsWithBalance,
      meta: {
        total_debt: totals.total_debt,
        total_credit: totals.total_credit,
        cursor: hasMore ? data[data.length - 1].id : null,
        hasMore,
      },
    };
  }

  /**
   * Cari detay (OkLif tarzı - üst kart + hareketler)
   */
  async findById(companyId: string, accountId: string) {
    const account = await this.prisma.account.findFirst({
      where: { id: accountId, company_id: companyId, deleted_at: null },
      include: {
        group: { select: { id: true, name: true } },
        account_tags: { include: { tag: true } },
      },
    });

    if (!account) throw new NotFoundException('Cari hesap bulunamadı.');

    const balance = await this.calculateBalance(
      accountId,
      account.opening_balance,
      account.opening_balance_direction,
    );

    // Toplam borç ve alacak
    const aggregates = await this.prisma.transaction.aggregate({
      where: { account_id: accountId, deleted_at: null },
      _sum: { amount: true },
    });

    const debitTotal = await this.prisma.transaction.aggregate({
      where: {
        account_id: accountId,
        deleted_at: null,
        type: { in: ['SALE', 'PURCHASE'] },
      },
      _sum: { amount: true },
    });

    const creditTotal = await this.prisma.transaction.aggregate({
      where: {
        account_id: accountId,
        deleted_at: null,
        type: { in: ['COLLECTION', 'PAYMENT'] },
      },
      _sum: { amount: true },
    });

    return {
      ...account,
      current_balance: balance,
      total_debit: debitTotal._sum.amount || 0,
      total_credit: creditTotal._sum.amount || 0,
    };
  }

  /**
   * Cari güncelle
   */
  async update(companyId: string, accountId: string, data: any) {
    const account = await this.prisma.account.findFirst({
      where: { id: accountId, company_id: companyId, deleted_at: null },
    });
    if (!account) throw new NotFoundException('Cari hesap bulunamadı.');

    return this.prisma.account.update({
      where: { id: accountId },
      data,
    });
  }

  /**
   * Cari sil/arşivle
   */
  async delete(companyId: string, accountId: string) {
    const account = await this.prisma.account.findFirst({
      where: { id: accountId, company_id: companyId },
    });
    if (!account) throw new NotFoundException('Cari hesap bulunamadı.');

    // Hareketi olan cari silinemez, arşivlenir
    const transactionCount = await this.prisma.transaction.count({
      where: { account_id: accountId, deleted_at: null },
    });

    if (transactionCount > 0) {
      await this.prisma.account.update({
        where: { id: accountId },
        data: { is_archived: true },
      });
      return { message: 'Hareketi olan cari silinemez, arşivlendi.' };
    }

    await this.prisma.account.update({
      where: { id: accountId },
      data: { deleted_at: new Date() },
    });
    return { message: 'Cari hesap silindi.' };
  }

  /**
   * Bakiye hesapla (sunucu tarafında, kuruş hassasiyetinde)
   * Müşteri: açılış + satışlar - tahsilatlar (pozitif = bize borçlu)
   * Tedarikçi: açılış + alışlar - ödemeler (negatif = biz borçluyuz)
   */
  async calculateBalance(
    accountId: string,
    openingBalance: number,
    openingDirection: BalanceDirection,
  ): Promise<number> {
    let balance = openingDirection === 'DEBIT' ? openingBalance : -openingBalance;

    // Borç artıran hareketler (satış, alış)
    const debits = await this.prisma.transaction.aggregate({
      where: {
        account_id: accountId,
        deleted_at: null,
        type: { in: ['SALE', 'PURCHASE', 'SALARY', 'ADVANCE'] },
      },
      _sum: { amount: true },
    });

    // Borç azaltan hareketler (tahsilat, ödeme)
    const credits = await this.prisma.transaction.aggregate({
      where: {
        account_id: accountId,
        deleted_at: null,
        type: { in: ['COLLECTION', 'PAYMENT'] },
      },
      _sum: { amount: true },
    });

    balance += (debits._sum.amount || 0) - (credits._sum.amount || 0);
    return balance;
  }

  /**
   * Otomatik cari kodu üret
   */
  private async generateCode(companyId: string, accountType: AccountType): Promise<string> {
    const prefixes: Record<AccountType, string> = {
      CUSTOMER: 'M',
      SUPPLIER: 'T',
      PERSONNEL: 'P',
      PARTNER: 'O',
      OTHER: 'D',
    };

    const prefix = prefixes[accountType];
    const lastAccount = await this.prisma.account.findFirst({
      where: {
        company_id: companyId,
        code: { startsWith: prefix + '-' },
      },
      orderBy: { code: 'desc' },
    });

    let nextNumber = 1;
    if (lastAccount) {
      const parts = lastAccount.code.split('-');
      nextNumber = parseInt(parts[1], 10) + 1;
    }

    return `${prefix}-${nextNumber.toString().padStart(4, '0')}`;
  }
}

