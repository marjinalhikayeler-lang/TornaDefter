/**
 * Çek/Senet Takibi Service
 * Portföy, durum değişikliği, ciro, vade takibi
 */
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ChequeNoteStatus, ChequeNoteDirection } from '@prisma/client';

@Injectable()
export class ChequesNotesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(companyId: string, data: any) {
    const rawDueDate = data.due_date || data.dueDate;
    const rawIssueDate = data.issue_date || data.issueDate;
    const dueDate = rawDueDate ? new Date(rawDueDate) : new Date(Date.now() + 30 * 86400000);
    const issueDate = rawIssueDate ? new Date(rawIssueDate) : null;

    return this.prisma.chequeNote.create({
      data: {
        company_id: companyId,
        type: data.type || 'CHEQUE',
        direction: data.direction || 'RECEIVED',
        amount: Number(data.amount) || 0,
        currency: data.currency || 'TRY',
        issue_date: issueDate && !isNaN(issueDate.getTime()) ? issueDate : null,
        due_date: !isNaN(dueDate.getTime()) ? dueDate : new Date(),
        cheque_number: data.cheque_number || data.chequeNumber || null,
        bank_name: data.bank_name || data.bankName || null,
        branch_name: data.branch_name || data.branchName || null,
        drawer: data.drawer || 'Bilinmeyen',
        related_account_id: data.related_account_id || data.relatedAccountId || null,
        description: data.description || null,
        photo_url: data.photo_url || data.photoUrl || null,
        status: data.status || 'IN_PORTFOLIO',
      },
    });
  }

  async findAll(companyId: string, filters: {
    direction?: ChequeNoteDirection;
    status?: ChequeNoteStatus;
    due_start?: string;
    due_end?: string;
    cursor?: string;
    limit?: number;
  }) {
    const limit = filters.limit || 50;
    const where: any = { company_id: companyId, deleted_at: null };
    if (filters.direction) where.direction = filters.direction;
    if (filters.status) where.status = filters.status;
    if (filters.due_start || filters.due_end) {
      where.due_date = {};
      if (filters.due_start) where.due_date.gte = new Date(filters.due_start);
      if (filters.due_end) where.due_date.lte = new Date(filters.due_end);
    }

    const items = await this.prisma.chequeNote.findMany({
      where,
      take: limit + 1,
      ...(filters.cursor ? { cursor: { id: filters.cursor }, skip: 1 } : {}),
      orderBy: { due_date: 'asc' },
      include: {
        related_account: { select: { id: true, title: true } },
      },
    });

    const hasMore = items.length > limit;
    const data = hasMore ? items.slice(0, limit) : items;

    // Toplam tutarlar
    const totals = await this.prisma.chequeNote.aggregate({
      where: { company_id: companyId, deleted_at: null, ...(filters.direction ? { direction: filters.direction } : {}) },
      _sum: { amount: true },
      _count: true,
    });

    return {
      data: data.map((cn) => ({
        ...cn,
        is_overdue: cn.due_date < new Date() && !['COLLECTED', 'PAID', 'CANCELLED'].includes(cn.status),
        days_until_due: Math.ceil((cn.due_date.getTime() - Date.now()) / 86400000),
      })),
      meta: {
        total_amount: totals._sum.amount || 0,
        total_count: totals._count,
        cursor: hasMore ? data[data.length - 1].id : null,
        hasMore,
      },
    };
  }

  /** Durum değişikliği (kasa/banka bakiyesine otomatik yansır) */
  async changeStatus(companyId: string, id: string, userId: string, newStatus: ChequeNoteStatus, bankAccountId?: string) {
    const cn = await this.prisma.chequeNote.findFirst({
      where: { id, company_id: companyId, deleted_at: null },
    });
    if (!cn) throw new NotFoundException('Çek/Senet bulunamadı.');

    return this.prisma.$transaction(async (tx) => {
      // Durum geçmişi
      await tx.chequeNoteHistory.create({
        data: {
          cheque_note_id: id,
          from_status: cn.status,
          to_status: newStatus,
          notes: bankAccountId || null,
          created_by: userId,
        },
      });

      // Tahsil/Ödeme edilince banka bakiyesini güncelle
      if (newStatus === 'COLLECTED' && bankAccountId) {
        await tx.bankAccount.update({
          where: { id: bankAccountId },
          data: { current_balance: { increment: cn.amount } },
        });
      } else if (newStatus === 'PAID' && bankAccountId) {
        await tx.bankAccount.update({
          where: { id: bankAccountId },
          data: { current_balance: { decrement: cn.amount } },
        });
      }

      return tx.chequeNote.update({
        where: { id },
        data: { status: newStatus },
      });
    });
  }

  /** Ciro (alınan çeki başka cariye devret) */
  async endorse(companyId: string, id: string, userId: string, targetAccountId: string) {
    const cn = await this.prisma.chequeNote.findFirst({
      where: { id, company_id: companyId, status: 'IN_PORTFOLIO', direction: 'RECEIVED' },
    });
    if (!cn) throw new BadRequestException('Sadece portföydeki alınan çekler ciro edilebilir.');

    return this.prisma.$transaction(async (tx) => {
      await tx.chequeNoteHistory.create({
        data: {
          cheque_note_id: id,
          from_status: 'IN_PORTFOLIO',
          to_status: 'ENDORSED',
          created_by: userId,
          notes: `Ciro edildi: ${targetAccountId}`,
        },
      });

      return tx.chequeNote.update({
        where: { id },
        data: { status: 'ENDORSED', endorsed_to_account_id: targetAccountId },
      });
    });
  }
}
