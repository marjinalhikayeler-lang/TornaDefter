import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Frequency, InstallmentStatus, PaymentMethod } from '@prisma/client';

@Injectable()
export class InstallmentsService {
  constructor(private prisma: PrismaService) {}

  // ============ TAKSİT PLANI OLUŞTUR ============
  async createPlan(
    companyId: string,
    dto: {
      accountId: string;
      transactionId?: string;
      title: string;
      totalAmount: number;
      installmentCount: number;
      startDate: string;
      frequency?: Frequency;
      notes?: string;
    },
  ) {
    if (dto.installmentCount < 2 || dto.installmentCount > 120) {
      throw new BadRequestException('Taksit sayısı 2 ile 120 arasında olmalıdır');
    }

    const account = await this.prisma.account.findFirst({
      where: { id: dto.accountId, company_id: companyId, deleted_at: null },
    });
    if (!account) throw new NotFoundException('Cari hesap bulunamadı');

    const installmentAmount = Math.floor(dto.totalAmount / dto.installmentCount);
    const remainder = dto.totalAmount - installmentAmount * dto.installmentCount;
    const freq = dto.frequency || Frequency.MONTHLY;

    return this.prisma.$transaction(async (tx) => {
      const plan = await tx.installmentPlan.create({
        data: {
          company_id: companyId,
          account_id: dto.accountId,
          transaction_id: dto.transactionId || null,
          title: dto.title,
          total_amount: dto.totalAmount,
          installment_count: dto.installmentCount,
          start_date: new Date(dto.startDate),
          frequency: freq,
          notes: dto.notes || null,
        },
      });

      const installments = [];
      for (let i = 0; i < dto.installmentCount; i++) {
        const dueDate = this.calculateDueDate(new Date(dto.startDate), freq, i);
        const amount = i === dto.installmentCount - 1 ? installmentAmount + remainder : installmentAmount;

        installments.push({
          plan_id: plan.id,
          installment_number: i + 1,
          amount,
          due_date: dueDate,
          status: InstallmentStatus.PENDING,
        });
      }

      await tx.installment.createMany({ data: installments });

      return tx.installmentPlan.findUnique({
        where: { id: plan.id },
        include: { installments: { orderBy: { installment_number: 'asc' } } },
      });
    });
  }

  // ============ TAKSİT PLANLARINI LİSTELE ============
  async listPlans(companyId: string, accountId?: string) {
    return this.prisma.installmentPlan.findMany({
      where: {
        company_id: companyId,
        ...(accountId ? { account_id: accountId } : {}),
        deleted_at: null,
      },
      include: {
        account: { select: { id: true, title: true, code: true } },
        installments: { orderBy: { installment_number: 'asc' }, where: { deleted_at: null } },
      },
      orderBy: { created_at: 'desc' },
    });
  }

  // ============ TAKSİT PLANI DETAY ============
  async getPlan(companyId: string, planId: string) {
    const plan = await this.prisma.installmentPlan.findFirst({
      where: { id: planId, company_id: companyId, deleted_at: null },
      include: {
        account: { select: { id: true, title: true, code: true, account_type: true } },
        installments: { orderBy: { installment_number: 'asc' }, where: { deleted_at: null } },
      },
    });
    if (!plan) throw new NotFoundException('Taksit planı bulunamadı');

    const paidCount = plan.installments.filter((i) => i.status === InstallmentStatus.PAID).length;
    const paidAmount = plan.installments
      .filter((i) => i.status === InstallmentStatus.PAID)
      .reduce((s, i) => s + (i.paid_amount || i.amount), 0);
    const remainingAmount = plan.total_amount - paidAmount;
    const overdueCount = plan.installments.filter(
      (i) => i.status === InstallmentStatus.PENDING && new Date(i.due_date) < new Date(),
    ).length;

    return {
      ...plan,
      summary: { paidCount, paidAmount, remainingAmount, overdueCount, totalCount: plan.installment_count },
    };
  }

  // ============ TAKSİT ÖDE ============
  async payInstallment(
    companyId: string,
    planId: string,
    installmentId: string,
    dto: { paidAmount?: number; paidDate?: string; paymentMethod?: PaymentMethod; notes?: string },
  ) {
    const plan = await this.prisma.installmentPlan.findFirst({
      where: { id: planId, company_id: companyId, deleted_at: null },
    });
    if (!plan) throw new NotFoundException('Taksit planı bulunamadı');

    const installment = await this.prisma.installment.findFirst({
      where: { id: installmentId, plan_id: planId, deleted_at: null },
    });
    if (!installment) throw new NotFoundException('Taksit bulunamadı');
    if (installment.status === InstallmentStatus.PAID) {
      throw new BadRequestException('Bu taksit zaten ödenmiş');
    }

    return this.prisma.installment.update({
      where: { id: installmentId },
      data: {
        status: InstallmentStatus.PAID,
        paid_amount: dto.paidAmount || installment.amount,
        paid_date: dto.paidDate ? new Date(dto.paidDate) : new Date(),
        payment_method: dto.paymentMethod || null,
        notes: dto.notes || installment.notes,
      },
    });
  }

  // ============ TAKSİT İPTAL ============
  async cancelInstallment(companyId: string, planId: string, installmentId: string) {
    const plan = await this.prisma.installmentPlan.findFirst({
      where: { id: planId, company_id: companyId, deleted_at: null },
    });
    if (!plan) throw new NotFoundException('Taksit planı bulunamadı');

    return this.prisma.installment.update({
      where: { id: installmentId },
      data: { status: InstallmentStatus.CANCELLED },
    });
  }

  // ============ TAKSİT PLANINI SİL ============
  async deletePlan(companyId: string, planId: string) {
    const plan = await this.prisma.installmentPlan.findFirst({
      where: { id: planId, company_id: companyId, deleted_at: null },
    });
    if (!plan) throw new NotFoundException('Taksit planı bulunamadı');

    return this.prisma.installmentPlan.update({
      where: { id: planId },
      data: { deleted_at: new Date() },
    });
  }

  // ============ GECİKMİŞ TAKSİTLERİ GÜNCELLE ============
  async updateOverdueInstallments(companyId: string) {
    const now = new Date();
    return this.prisma.installment.updateMany({
      where: {
        plan: { company_id: companyId, deleted_at: null },
        status: InstallmentStatus.PENDING,
        due_date: { lt: now },
        deleted_at: null,
      },
      data: { status: InstallmentStatus.OVERDUE },
    });
  }

  // ============ ÖZET ============
  async getSummary(companyId: string) {
    const plans = await this.prisma.installmentPlan.findMany({
      where: { company_id: companyId, deleted_at: null },
      include: { installments: { where: { deleted_at: null } } },
    });

    let totalPlans = plans.length;
    let totalAmount = 0;
    let paidAmount = 0;
    let pendingCount = 0;
    let overdueCount = 0;
    const now = new Date();

    for (const plan of plans) {
      totalAmount += plan.total_amount;
      for (const inst of plan.installments) {
        if (inst.status === InstallmentStatus.PAID) {
          paidAmount += inst.paid_amount || inst.amount;
        } else if (inst.status === InstallmentStatus.PENDING) {
          if (new Date(inst.due_date) < now) overdueCount++;
          else pendingCount++;
        }
      }
    }

    return { totalPlans, totalAmount, paidAmount, remainingAmount: totalAmount - paidAmount, pendingCount, overdueCount };
  }

  // ============ YARDIMCI ============
  private calculateDueDate(start: Date, freq: Frequency, index: number): Date {
    const d = new Date(start);
    switch (freq) {
      case Frequency.WEEKLY:
        d.setDate(d.getDate() + 7 * index);
        break;
      case Frequency.MONTHLY:
        d.setMonth(d.getMonth() + index);
        break;
      case Frequency.YEARLY:
        d.setFullYear(d.getFullYear() + index);
        break;
    }
    return d;
  }
}

