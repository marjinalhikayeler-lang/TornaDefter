/**
 * Transactions Service - Hareket/İşlem İş Mantığı
 * OkLif tarzı: Borç Ekle, Tahsilat Al, Ödeme Yap
 * Ödeme yöntemi (Nakit/K.Kartı/Havale/Çek/Senet) + rozet
 */
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { TransactionType, PaymentMethod } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class TransactionsService {
  private readonly logger = new Logger(TransactionsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Hareket oluştur (OkLif "+" butonu akışı)
   * - Borç Ekle (Satış)
   * - Tahsilat Al
   * - Alacak Ekle (Alış)
   * - Ödeme Yap
   * Her birinde ödeme yöntemi seçilebilir
   */
  async create(companyId: string, userId: string, data: any) {
    const accountId = data.account_id || data.accountId;
    const type = data.type as TransactionType;
    const amount = Number(data.amount) || 0;
    const description = data.description || null;
    const documentNumber = data.document_number || data.documentNumber;
    const date = data.date;
    const dueDate = data.due_date || data.dueDate;
    const paymentMethod = (data.payment_method || data.paymentMethod || 'CASH') as PaymentMethod;
    const cashAccountId = data.cash_account_id || data.cashAccountId || null;
    const bankAccountId = data.bank_account_id || data.bankAccountId || null;
    const categoryId = data.category_id || data.categoryId || null;
    const notes = data.notes || null;
    const idempotencyKey = data.idempotency_key || data.idempotencyKey;

    if (amount <= 0) {
      throw new BadRequestException('Tutar sıfırdan büyük olmalıdır.');
    }

    if (!accountId) {
      throw new BadRequestException('Cari hesap (accountId) seçilmelidir.');
    }

    // İdempotency kontrolü
    if (idempotencyKey) {
      const existing = await this.prisma.transaction.findUnique({
        where: { idempotency_key: idempotencyKey },
      });
      if (existing) return existing;
    }

    // Cari kontrolü
    const account = await this.prisma.account.findFirst({
      where: { id: accountId, company_id: companyId, deleted_at: null },
    });
    if (!account) throw new NotFoundException('Cari hesap bulunamadı.');

    // Risk limiti kontrolü (borçlandırma işlemlerinde)
    if (['SALE', 'PURCHASE'].includes(type) && account.risk_limit) {
      const currentBalance = await this.calculateRunningBalance(accountId);
      if (currentBalance + amount > account.risk_limit) {
        this.logger.warn(`Risk limiti uyarısı: ${account.title} - Limit: ${account.risk_limit}, Yeni bakiye: ${currentBalance + amount}`);
      }
    }

    // Mükerrer kontrolü (aynı cari, tutar, tarih)
    const duplicate = await this.prisma.transaction.findFirst({
      where: {
        account_id: accountId,
        amount: amount,
        date: new Date(date),
        type: type,
        deleted_at: null,
        created_at: { gte: new Date(Date.now() - 60000) }, // Son 1 dakika
      },
    });
    if (duplicate) {
      this.logger.warn(`Mükerrer hareket uyarısı: ${account.title} - ${amount}`);
    }

    return this.prisma.$transaction(async (tx) => {
      // Hareketi oluştur
      const transaction = await tx.transaction.create({
        data: {
          company_id: companyId,
          account_id: accountId,
          type: type,
          amount: amount,
          description: description,
          document_number: documentNumber || await this.generateDocumentNumber(companyId),
          date: new Date(date),
          due_date: dueDate ? new Date(dueDate) : null,
          payment_method: paymentMethod,
          cash_account_id: cashAccountId,
          bank_account_id: bankAccountId,
          category_id: categoryId,
          notes: notes,
          idempotency_key: idempotencyKey || uuidv4(),
          created_by: userId,
          running_balance: 0, // Sonra hesaplanacak
        },
      });

      // Yürüyen bakiyeyi güncelle
      const newBalance = await this.recalculateRunningBalances(tx, accountId);

      // Kasa/Banka bakiyesini güncelle
      if (paymentMethod === 'CASH' && cashAccountId) {
        await this.updateCashBalance(tx, cashAccountId, type, amount);
      } else if (
        (paymentMethod === 'BANK_TRANSFER' || paymentMethod === 'CREDIT_CARD') &&
        bankAccountId
      ) {
        await this.updateBankBalance(tx, bankAccountId, type, amount);
      }

      // Denetim kaydı
      await tx.auditLog.create({
        data: {
          company_id: companyId,
          user_id: userId,
          action: 'CREATE',
          entity_type: 'transaction',
          entity_id: transaction.id,
          new_values: {
            type: data.type,
            amount: data.amount,
            payment_method: data.payment_method,
            description: data.description,
          },
        },
      });

      return {
        ...transaction,
        running_balance: newBalance,
        // OkLif tarzı rozet bilgileri
        payment_label: this.getPaymentLabel(data.type, data.payment_method),
        balance_label: this.getBalanceLabel(data.type),
      };
    });
  }

  /**
   * Cari hareketleri listele (OkLif cari detay ekranı)
   */
  async findByAccount(companyId: string, accountId: string, filters: {
    start_date?: string;
    end_date?: string;
    type?: TransactionType;
    payment_method?: PaymentMethod;
    cursor?: string;
    limit?: number;
  }) {
    const limit = filters.limit || 50;
    const where: any = {
      company_id: companyId,
      account_id: accountId,
      deleted_at: null,
    };

    if (filters.start_date || filters.end_date) {
      where.date = {};
      if (filters.start_date) where.date.gte = new Date(filters.start_date);
      if (filters.end_date) where.date.lte = new Date(filters.end_date);
    }
    if (filters.type) where.type = filters.type;
    if (filters.payment_method) where.payment_method = filters.payment_method;

    const transactions = await this.prisma.transaction.findMany({
      where,
      take: limit + 1,
      ...(filters.cursor ? { cursor: { id: filters.cursor }, skip: 1 } : {}),
      orderBy: { date: 'desc' },
      include: {
        attachments: { select: { id: true, file_name: true, file_url: true } },
      },
    });

    const hasMore = transactions.length > limit;
    const data = hasMore ? transactions.slice(0, limit) : transactions;

    // OkLif tarzı rozet ve etiket ekle
    const enrichedData = data.map((t) => ({
      ...t,
      payment_label: this.getPaymentLabel(t.type, t.payment_method),
      balance_label: this.getBalanceLabel(t.type),
      is_overdue: t.due_date && t.due_date < new Date() && !['COLLECTION', 'PAYMENT'].includes(t.type),
      overdue_days: t.due_date ? Math.max(0, Math.floor((Date.now() - t.due_date.getTime()) / 86400000)) : null,
    }));

    return {
      data: enrichedData,
      meta: {
        cursor: hasMore ? data[data.length - 1].id : null,
        hasMore,
      },
    };
  }

  /**
   * Tüm hareketler (genel liste)
   */
  async findAll(companyId: string, filters: {
    start_date?: string;
    end_date?: string;
    type?: TransactionType;
    account_id?: string;
    payment_method?: PaymentMethod;
    cursor?: string;
    limit?: number;
  }) {
    const limit = filters.limit || 50;
    const where: any = { company_id: companyId, deleted_at: null };

    if (filters.start_date || filters.end_date) {
      where.date = {};
      if (filters.start_date) where.date.gte = new Date(filters.start_date);
      if (filters.end_date) where.date.lte = new Date(filters.end_date);
    }
    if (filters.type) where.type = filters.type;
    if (filters.account_id) where.account_id = filters.account_id;
    if (filters.payment_method) where.payment_method = filters.payment_method;

    const transactions = await this.prisma.transaction.findMany({
      where,
      take: limit + 1,
      ...(filters.cursor ? { cursor: { id: filters.cursor }, skip: 1 } : {}),
      orderBy: { date: 'desc' },
      include: {
        account: { select: { id: true, title: true, code: true, account_type: true } },
      },
    });

    const hasMore = transactions.length > limit;
    const data = hasMore ? transactions.slice(0, limit) : transactions;

    return {
      data: data.map((t) => ({
        ...t,
        payment_label: this.getPaymentLabel(t.type, t.payment_method),
        balance_label: this.getBalanceLabel(t.type),
      })),
      meta: { cursor: hasMore ? data[data.length - 1].id : null, hasMore },
    };
  }

  /**
   * Hareket güncelle
   */
  async update(companyId: string, transactionId: string, userId: string, data: any) {
    const existing = await this.prisma.transaction.findFirst({
      where: { id: transactionId, company_id: companyId, deleted_at: null },
    });
    if (!existing) throw new NotFoundException('Hareket bulunamadı.');

    return this.prisma.$transaction(async (tx) => {
      // Eski değeri denetim kaydına yaz
      await tx.auditLog.create({
        data: {
          company_id: companyId,
          user_id: userId,
          action: 'UPDATE',
          entity_type: 'transaction',
          entity_id: transactionId,
          old_values: existing as any,
          new_values: data,
        },
      });

      const updated = await tx.transaction.update({
        where: { id: transactionId },
        data: {
          ...data,
          date: data.date ? new Date(data.date) : undefined,
          due_date: data.due_date ? new Date(data.due_date) : undefined,
        },
      });

      // Bakiyeleri yeniden hesapla
      await this.recalculateRunningBalances(tx, existing.account_id);

      return updated;
    });
  }

  /**
   * Hareket sil (soft delete)
   */
  async delete(companyId: string, transactionId: string, userId: string) {
    const existing = await this.prisma.transaction.findFirst({
      where: { id: transactionId, company_id: companyId, deleted_at: null },
    });
    if (!existing) throw new NotFoundException('Hareket bulunamadı.');

    return this.prisma.$transaction(async (tx) => {
      await tx.auditLog.create({
        data: {
          company_id: companyId,
          user_id: userId,
          action: 'DELETE',
          entity_type: 'transaction',
          entity_id: transactionId,
          old_values: existing as any,
        },
      });

      await tx.transaction.update({
        where: { id: transactionId },
        data: { deleted_at: new Date() },
      });

      await this.recalculateRunningBalances(tx, existing.account_id);

      return { message: 'Hareket silindi. 30 gün çöp kutusunda tutulacak.' };
    });
  }

  // ============ Yardımcı Metodlar ============

  /**
   * OkLif tarzı ödeme rozeti (hareket altında gösterilen metin)
   * Ör: "K.Kartı ile Ödeme Yapıldı", "Nakit Tahsilat", "Havale / Eft Gönderildi"
   */
  private getPaymentLabel(type: TransactionType, method?: PaymentMethod | null): string {
    const methodLabels: Record<string, string> = {
      CASH: 'Nakit',
      BANK_TRANSFER: 'Havale / Eft',
      CREDIT_CARD: 'K.Kartı ile',
      CHEQUE: 'Çek',
      PROMISSORY_NOTE: 'Senet',
    };

    const methodText = method ? methodLabels[method] || '' : '';

    switch (type) {
      case 'SALE': return 'Borç Eklendi';
      case 'COLLECTION': return method ? `${methodText} Tahsilat` : 'Tahsilat Alındı';
      case 'PURCHASE': return 'Alacak Eklendi';
      case 'PAYMENT': return method ? `${methodText} Ödeme Yapıldı` : 'Ödeme Yapıldı';
      case 'SALARY': return 'Maaş Ödendi';
      case 'ADVANCE': return 'Avans Verildi';
      case 'OFFSET': return 'Mahsup Yapıldı';
      case 'CORRECTION': return 'Bakiye Düzeltildi';
      default: return '';
    }
  }

  /**
   * OkLif tarzı bakiye etiketi (hareket tipi göstergesi)
   */
  private getBalanceLabel(type: TransactionType): string {
    switch (type) {
      case 'SALE': return 'Yapılan Satış';
      case 'COLLECTION': return 'Tahsilat';
      case 'PURCHASE': return 'Alınan Ürünler';
      case 'PAYMENT': return 'Yapılan Ödeme';
      case 'SALARY': return 'Maaş Ödemesi';
      case 'ADVANCE': return 'Avans';
      case 'OFFSET': return 'Mahsup';
      case 'CORRECTION': return 'Düzeltme';
      default: return '';
    }
  }

  private async calculateRunningBalance(accountId: string): Promise<number> {
    const account = await this.prisma.account.findUnique({ where: { id: accountId } });
    if (!account) return 0;

    let balance = account.opening_balance_direction === 'DEBIT'
      ? account.opening_balance
      : -account.opening_balance;

    const debits = await this.prisma.transaction.aggregate({
      where: { account_id: accountId, deleted_at: null, type: { in: ['SALE', 'PURCHASE', 'SALARY', 'ADVANCE'] } },
      _sum: { amount: true },
    });
    const credits = await this.prisma.transaction.aggregate({
      where: { account_id: accountId, deleted_at: null, type: { in: ['COLLECTION', 'PAYMENT'] } },
      _sum: { amount: true },
    });

    return balance + (debits._sum.amount || 0) - (credits._sum.amount || 0);
  }

  private async recalculateRunningBalances(tx: any, accountId: string): Promise<number> {
    const account = await tx.account.findUnique({ where: { id: accountId } });
    if (!account) return 0;

    let balance = account.opening_balance_direction === 'DEBIT'
      ? account.opening_balance
      : -account.opening_balance;

    const transactions = await tx.transaction.findMany({
      where: { account_id: accountId, deleted_at: null },
      orderBy: { date: 'asc' },
    });

    for (const t of transactions) {
      if (['SALE', 'PURCHASE', 'SALARY', 'ADVANCE'].includes(t.type)) {
        balance += t.amount;
      } else if (['COLLECTION', 'PAYMENT'].includes(t.type)) {
        balance -= t.amount;
      }

      await tx.transaction.update({
        where: { id: t.id },
        data: { running_balance: balance },
      });
    }

    return balance;
  }

  private async generateDocumentNumber(companyId: string): Promise<string> {
    const count = await this.prisma.transaction.count({
      where: { company_id: companyId },
    });
    return (count + 1).toString().padStart(8, '0');
  }

  private async updateCashBalance(tx: any, cashAccountId: string, type: TransactionType, amount: number) {
    const isInflow = ['COLLECTION'].includes(type);
    await tx.cashAccount.update({
      where: { id: cashAccountId },
      data: {
        current_balance: { [isInflow ? 'increment' : 'decrement']: amount },
      },
    });
  }

  private async updateBankBalance(tx: any, bankAccountId: string, type: TransactionType, amount: number) {
    const isInflow = ['COLLECTION'].includes(type);
    await tx.bankAccount.update({
      where: { id: bankAccountId },
      data: {
        current_balance: { [isInflow ? 'increment' : 'decrement']: amount },
      },
    });
  }
}

