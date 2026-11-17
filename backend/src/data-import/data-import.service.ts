import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AccountType, BalanceDirection } from '@prisma/client';
import * as ExcelJS from 'exceljs';

@Injectable()
export class DataImportService {
  constructor(private prisma: PrismaService) {}

  // ============ EXCEL/CSV İÇE AKTARMA ============
  async importAccounts(
    companyId: string,
    userId: string,
    fileBuffer: any,
    fileName: string,
    sourceApp?: string,
  ) {
    const importRecord = await this.prisma.dataImport.create({
      data: {
        company_id: companyId,
        file_name: fileName,
        file_type: fileName.endsWith('.csv') ? 'csv' : 'excel',
        source_app: sourceApp || null,
        status: 'processing',
        imported_by: userId,
      },
    });

    try {
      const workbook = new ExcelJS.Workbook();

      if (fileName.endsWith('.csv')) {
        await workbook.csv.read(require('stream').Readable.from(fileBuffer));
      } else {
        await workbook.xlsx.load(fileBuffer);
      }

      const worksheet = workbook.worksheets[0];
      if (!worksheet) throw new BadRequestException('Dosyada çalışma sayfası bulunamadı');

      const rows: any[] = [];
      const errors: any[] = [];
      let successCount = 0;
      let errorCount = 0;
      let rowIndex = 0;

      worksheet.eachRow((row, rowNumber) => {
        if (rowNumber === 1) return; // Başlık satırını atla
        rowIndex++;

        const title = row.getCell(1)?.value?.toString()?.trim();
        const typeStr = row.getCell(2)?.value?.toString()?.trim()?.toUpperCase();
        const phone = row.getCell(3)?.value?.toString()?.trim() || null;
        const email = row.getCell(4)?.value?.toString()?.trim() || null;
        const address = row.getCell(5)?.value?.toString()?.trim() || null;
        const taxOffice = row.getCell(6)?.value?.toString()?.trim() || null;
        const taxNumber = row.getCell(7)?.value?.toString()?.trim() || null;
        const openingBalanceStr = row.getCell(8)?.value?.toString()?.trim() || '0';
        const directionStr = row.getCell(9)?.value?.toString()?.trim()?.toUpperCase() || 'DEBIT';
        const notes = row.getCell(10)?.value?.toString()?.trim() || null;

        if (!title) {
          errors.push({ row: rowNumber, error: 'Cari hesap adı boş' });
          errorCount++;
          return;
        }

        let accountType: AccountType = AccountType.CUSTOMER;
        if (typeStr === 'TEDARİKÇİ' || typeStr === 'SUPPLIER' || typeStr === 'T') {
          accountType = AccountType.SUPPLIER;
        } else if (typeStr === 'PERSONEL' || typeStr === 'PERSONNEL' || typeStr === 'P') {
          accountType = AccountType.PERSONNEL;
        } else if (typeStr === 'ORTAK' || typeStr === 'PARTNER' || typeStr === 'O') {
          accountType = AccountType.PARTNER;
        }

        const openingBalance = Math.round(parseFloat(openingBalanceStr.replace(',', '.')) * 100) || 0;
        const direction = directionStr === 'ALACAK' || directionStr === 'CREDIT'
          ? BalanceDirection.CREDIT
          : BalanceDirection.DEBIT;

        rows.push({
          title,
          accountType,
          phone,
          email,
          address,
          taxOffice,
          taxNumber,
          openingBalance,
          direction,
          notes,
        });
      });

      // Toplu oluşturma
      const prefix: Record<string, string> = {
        CUSTOMER: 'M',
        SUPPLIER: 'T',
        PERSONNEL: 'P',
        PARTNER: 'O',
        OTHER: 'D',
      };

      for (const row of rows) {
        try {
          // Kod üret
          const pfx = prefix[row.accountType] || 'D';
          const lastAccount = await this.prisma.account.findFirst({
            where: { company_id: companyId, code: { startsWith: pfx + '-' } },
            orderBy: { code: 'desc' },
          });
          const lastNum = lastAccount ? parseInt(lastAccount.code.split('-')[1]) || 0 : 0;
          const code = `${pfx}-${String(lastNum + 1).padStart(4, '0')}`;

          await this.prisma.account.create({
            data: {
              company_id: companyId,
              code,
              title: row.title,
              account_type: row.accountType,
              phones: row.phone ? JSON.stringify([row.phone]) : undefined,
              email: row.email,
              address: row.address,
              tax_office: row.taxOffice,
              tax_number: row.taxNumber,
              opening_balance: row.openingBalance,
              opening_balance_direction: row.direction,
              notes: row.notes,
            },
          });
          successCount++;
        } catch (err: any) {
          errors.push({ row: rows.indexOf(row) + 2, error: err.message || 'Bilinmeyen hata' });
          errorCount++;
        }
      }

      await this.prisma.dataImport.update({
        where: { id: importRecord.id },
        data: {
          total_rows: rows.length + errorCount,
          success_rows: successCount,
          error_rows: errorCount,
          errors: errors.length > 0 ? errors : undefined,
          status: errorCount > 0 && successCount === 0 ? 'failed' : 'completed',
        },
      });

      return {
        id: importRecord.id,
        totalRows: rows.length + errorCount,
        successRows: successCount,
        errorRows: errorCount,
        errors,
      };
    } catch (err: any) {
      await this.prisma.dataImport.update({
        where: { id: importRecord.id },
        data: { status: 'failed', errors: { message: err.message } },
      });
      throw new BadRequestException(`Dosya işlenirken hata: ${err.message}`);
    }
  }

  // ============ İÇE AKTARMA GEÇMİŞİ ============
  async listImports(companyId: string) {
    return this.prisma.dataImport.findMany({
      where: { company_id: companyId },
      orderBy: { created_at: 'desc' },
    });
  }

  // ============ İÇE AKTARMA DETAY ============
  async getImport(companyId: string, importId: string) {
    const record = await this.prisma.dataImport.findFirst({
      where: { id: importId, company_id: companyId },
    });
    if (!record) throw new NotFoundException('İçe aktarma kaydı bulunamadı');
    return record;
  }

  // ============ ŞABLON İNDİR ============
  async getTemplate(): Promise<Buffer> {
    const workbook = new ExcelJS.Workbook();
    const ws = workbook.addWorksheet('Cari Hesaplar');

    ws.columns = [
      { header: 'Cari Adı *', key: 'title', width: 30 },
      { header: 'Tür (M/T/P/O)', key: 'type', width: 15 },
      { header: 'Telefon', key: 'phone', width: 18 },
      { header: 'E-posta', key: 'email', width: 25 },
      { header: 'Adres', key: 'address', width: 35 },
      { header: 'Vergi Dairesi', key: 'taxOffice', width: 20 },
      { header: 'Vergi No', key: 'taxNumber', width: 15 },
      { header: 'Açılış Bakiyesi', key: 'openingBalance', width: 15 },
      { header: 'Yön (BORÇ/ALACAK)', key: 'direction', width: 18 },
      { header: 'Notlar', key: 'notes', width: 30 },
    ];

    // Örnek satır
    ws.addRow({
      title: 'Örnek Müşteri A.Ş.',
      type: 'M',
      phone: '0532 123 4567',
      email: 'info@ornek.com',
      address: 'İstanbul',
      taxOffice: 'Kadıköy',
      taxNumber: '1234567890',
      openingBalance: '1500.50',
      direction: 'BORÇ',
      notes: 'Örnek kayıt',
    });

    // Başlık stili
    ws.getRow(1).eachCell((cell) => {
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1E3A5F' } };
      cell.font = { color: { argb: 'FFFFFFFF' }, bold: true };
    });

    return (await workbook.xlsx.writeBuffer()) as unknown as Buffer;
  }
}

