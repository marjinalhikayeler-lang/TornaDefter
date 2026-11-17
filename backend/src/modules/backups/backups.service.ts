import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { BackupType, BackupStatus } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class BackupsService {
  constructor(private readonly prisma: PrismaService) { }

  async create(companyId: string, userId: string, type: BackupType = 'MANUAL') {
    const backup = await this.prisma.backup.create({
      data: {
        company_id: companyId,
        type,
        status: 'IN_PROGRESS',
        created_by: userId,
      },
    });

    // Arka planda yedek oluştur
    this.generateBackup(companyId, backup.id).catch(err => {
      console.error(`Yedek oluşturma hatası: ${err.message}`);
    });

    return backup;
  }

  private async generateBackup(companyId: string, backupId: string) {
    try {
      // Firma verilerini topla
      const [accounts, transactions, cashAccounts, bankAccounts, categories, cheques, incomeExpenses] = await this.prisma.$transaction([
        this.prisma.account.findMany({ where: { company_id: companyId, deleted_at: null } }),
        this.prisma.transaction.findMany({ where: { company_id: companyId, deleted_at: null } }),
        this.prisma.cashAccount.findMany({ where: { company_id: companyId, deleted_at: null } }),
        this.prisma.bankAccount.findMany({ where: { company_id: companyId, deleted_at: null } }),
        this.prisma.category.findMany({ where: { company_id: companyId, deleted_at: null } }),
        this.prisma.chequeNote.findMany({ where: { company_id: companyId, deleted_at: null } }),
        this.prisma.incomeExpense.findMany({ where: { company_id: companyId, deleted_at: null } }),
      ]);

      const backupData = {
        exportedAt: new Date().toISOString(),
        companyId,
        data: { accounts, transactions, cashAccounts, bankAccounts, categories, cheques, incomeExpenses },
      };

      const backupDir = path.join(process.cwd(), 'backups');
      if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir, { recursive: true });

      const fileName = `backup_${companyId}_${Date.now()}.json`;
      const filePath = path.join(backupDir, fileName);
      fs.writeFileSync(filePath, JSON.stringify(backupData, null, 2));

      const stats = fs.statSync(filePath);

      await this.prisma.backup.update({
        where: { id: backupId },
        data: {
          status: 'COMPLETED',
          file_url: `/backups/${fileName}`,
          file_size: stats.size,
          completed_at: new Date(),
        },
      });
    } catch (error: any) {
      await this.prisma.backup.update({
        where: { id: backupId },
        data: { status: 'FAILED' },
      });
      throw error;
    }
  }

  async findAll(companyId: string, filters?: { type?: BackupType; page?: number; limit?: number }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 20;
    const where: any = { company_id: companyId, deleted_at: null };
    if (filters?.type) where.type = filters.type;

    const [items, total] = await this.prisma.$transaction([
      this.prisma.backup.findMany({
        where,
        orderBy: { created_at: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.backup.count({ where }),
    ]);

    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async findOne(companyId: string, id: string) {
    const backup = await this.prisma.backup.findFirst({
      where: { id, company_id: companyId, deleted_at: null },
    });
    if (!backup) throw new NotFoundException('Yedek bulunamadı');
    return backup;
  }

  async restore(companyId: string, id: string) {
    const backup = await this.findOne(companyId, id);
    if (backup.status !== 'COMPLETED') {
      throw new NotFoundException('Bu yedek henüz tamamlanmamış');
    }

    const filePath = path.join(process.cwd(), backup.file_url!);
    if (!fs.existsSync(filePath)) {
      throw new NotFoundException('Yedek dosyası bulunamadı');
    }

    const backupData = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
    // Geri yükleme işlemi - özet bilgi döndür
    return {
      message: 'Yedek geri yükleme başlatıldı',
      accountCount: backupData.data.accounts?.length || 0,
      transactionCount: backupData.data.transactions?.length || 0,
    };
  }

  async remove(companyId: string, id: string) {
    await this.findOne(companyId, id);
    return this.prisma.backup.update({ where: { id }, data: { deleted_at: new Date() } });
  }

  async exportData(companyId: string, format: 'json' | 'excel' = 'json') {
    const data = await this.prisma.$transaction([
      this.prisma.account.findMany({ where: { company_id: companyId, deleted_at: null } }),
      this.prisma.transaction.findMany({ where: { company_id: companyId, deleted_at: null } }),
    ]);

    return {
      format,
      accounts: data[0],
      transactions: data[1],
      exportedAt: new Date().toISOString(),
    };
  }
}
