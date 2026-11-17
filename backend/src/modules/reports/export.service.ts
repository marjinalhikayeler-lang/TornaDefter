/**
 * TornaDefter - Rapor Export Servisi
 *
 * PDF, Excel, Word (DOC), JPEG, ODS, ODT formatlarında dışa aktarma
 */
import { Injectable } from '@nestjs/common';
import * as ExcelJS from 'exceljs';

@Injectable()
export class ExportService {
  // ============ EXCEL EXPORT ============
  async toExcel(title: string, columns: { header: string; key: string; width?: number }[], data: any[]): Promise<Buffer> {
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'TornaDefter';
    workbook.created = new Date();

    const ws = workbook.addWorksheet(title);
    ws.columns = columns;

    // Başlık stili
    ws.getRow(1).eachCell((cell) => {
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1E3A5F' } };
      cell.font = { color: { argb: 'FFFFFFFF' }, bold: true, size: 11 };
      cell.alignment = { horizontal: 'center', vertical: 'middle' };
      cell.border = {
        top: { style: 'thin' }, bottom: { style: 'thin' },
        left: { style: 'thin' }, right: { style: 'thin' },
      };
    });

    for (const row of data) {
      const r = ws.addRow(row);
      r.eachCell((cell) => {
        cell.border = {
          top: { style: 'thin' }, bottom: { style: 'thin' },
          left: { style: 'thin' }, right: { style: 'thin' },
        };
      });
    }

    return (await workbook.xlsx.writeBuffer()) as unknown as Buffer;
  }

  // ============ ODS EXPORT (OpenDocument Spreadsheet) ============
  async toOds(title: string, columns: { header: string; key: string; width?: number }[], data: any[]): Promise<Buffer> {
    // ExcelJS desteklemediği için CSV benzeri bir format oluşturuyoruz
    // Gerçek ODS için 'ods' paketine ihtiyaç var, ama Excel uyumlu xlsx dönüyoruz
    // ODS aslında zip içinde XML - basit bir çözüm olarak xlsx kullanıyoruz
    // LibreOffice xlsx'i doğrudan açabilir
    return this.toExcel(title, columns, data);
  }

  // ============ PDF EXPORT (HTML tabanlı) ============
  generatePdfHtml(
    title: string,
    companyName: string,
    columns: { header: string; key: string }[],
    data: any[],
    summary?: Record<string, string>,
  ): string {
    const headerCells = columns.map((c) => `<th>${c.header}</th>`).join('');
    const bodyRows = data
      .map((row) => {
        const cells = columns.map((c) => `<td>${row[c.key] ?? ''}</td>`).join('');
        return `<tr>${cells}</tr>`;
      })
      .join('');

    const summaryHtml = summary
      ? `<div class="summary">${Object.entries(summary)
        .map(([k, v]) => `<div class="summary-item"><span>${k}:</span><strong>${v}</strong></div>`)
        .join('')}</div>`
      : '';

    return `<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<title>${title}</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Segoe UI', Arial, sans-serif; padding: 30px; color: #1a1a2e; }
  .header { text-align: center; margin-bottom: 25px; border-bottom: 3px solid #1E3A5F; padding-bottom: 15px; }
  .header h1 { color: #1E3A5F; font-size: 22px; margin-bottom: 5px; }
  .header .company { color: #666; font-size: 14px; }
  .header .date { color: #999; font-size: 12px; margin-top: 5px; }
  table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 12px; }
  th { background: #1E3A5F; color: white; padding: 10px 8px; text-align: left; }
  td { padding: 8px; border-bottom: 1px solid #e0e0e0; }
  tr:nth-child(even) { background: #f8f9fa; }
  .summary { display: flex; gap: 20px; margin-top: 20px; padding: 15px; background: #f0f4f8; border-radius: 8px; }
  .summary-item span { color: #666; } .summary-item strong { color: #1E3A5F; margin-left: 5px; }
  .footer { margin-top: 30px; text-align: center; color: #999; font-size: 10px; border-top: 1px solid #e0e0e0; padding-top: 10px; }
  .debit { color: #DC2626; } .credit { color: #16A34A; }
</style>
</head>
<body>
  <div class="header">
    <h1>⚙ TornaDefter</h1>
    <div class="company">${companyName}</div>
    <div class="date">${title} - ${new Date().toLocaleDateString('tr-TR')}</div>
  </div>
  ${summaryHtml}
  <table><thead><tr>${headerCells}</tr></thead><tbody>${bodyRows}</tbody></table>
  <div class="footer">TornaDefter Cari Hesap Yönetim Sistemi © ${new Date().getFullYear()}</div>
</body>
</html>`;
  }

  // ============ WORD (DOC) EXPORT - HTML tabanlı ============
  generateWordHtml(
    title: string,
    companyName: string,
    columns: { header: string; key: string }[],
    data: any[],
  ): Buffer {
    const html = `<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:w="urn:schemas-microsoft-com:office:word"
      xmlns="http://www.w3.org/TR/REC-html40">
<head>
<meta charset="UTF-8">
<title>${title}</title>
<!--[if gte mso 9]><xml><w:WordDocument><w:View>Print</w:View></w:WordDocument></xml><![endif]-->
<style>
  body { font-family: Calibri, Arial, sans-serif; }
  h1 { color: #1E3A5F; text-align: center; }
  h3 { color: #666; text-align: center; margin-bottom: 20px; }
  table { width: 100%; border-collapse: collapse; }
  th { background: #1E3A5F; color: white; padding: 8px; text-align: left; border: 1px solid #ccc; }
  td { padding: 6px 8px; border: 1px solid #ccc; }
  .footer { margin-top: 20px; text-align: center; color: #999; font-size: 10px; }
</style>
</head>
<body>
  <h1>TornaDefter - ${title}</h1>
  <h3>${companyName} | ${new Date().toLocaleDateString('tr-TR')}</h3>
  <table>
    <tr>${columns.map((c) => `<th>${c.header}</th>`).join('')}</tr>
    ${data.map((row) => `<tr>${columns.map((c) => `<td>${row[c.key] ?? ''}</td>`).join('')}</tr>`).join('')}
  </table>
  <div class="footer">TornaDefter © ${new Date().getFullYear()}</div>
</body>
</html>`;
    return Buffer.from(html, 'utf-8');
  }

  // ============ JPEG EXPORT (HTML → Canvas sunucu tarafı) ============
  // Not: Gerçek JPEG için Puppeteer veya Sharp gerekir.
  // Basit çözüm: SVG tabanlı tablo görüntüsü oluşturuyoruz
  generateTableSvg(
    title: string,
    columns: { header: string; key: string }[],
    data: any[],
  ): string {
    const colWidth = 150;
    const rowHeight = 30;
    const width = columns.length * colWidth;
    const height = (data.length + 2) * rowHeight + 60;

    let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
    <rect width="${width}" height="${height}" fill="white"/>
    <text x="${width / 2}" y="30" text-anchor="middle" font-size="18" font-family="Arial" fill="#1E3A5F" font-weight="bold">${title}</text>`;

    // Header
    const headerY = 50;
    columns.forEach((col, i) => {
      svg += `<rect x="${i * colWidth}" y="${headerY}" width="${colWidth}" height="${rowHeight}" fill="#1E3A5F"/>`;
      svg += `<text x="${i * colWidth + 10}" y="${headerY + 20}" font-size="12" font-family="Arial" fill="white">${col.header}</text>`;
    });

    // Rows
    data.forEach((row, ri) => {
      const y = headerY + (ri + 1) * rowHeight;
      const bg = ri % 2 === 0 ? '#f8f9fa' : 'white';
      columns.forEach((col, ci) => {
        svg += `<rect x="${ci * colWidth}" y="${y}" width="${colWidth}" height="${rowHeight}" fill="${bg}" stroke="#e0e0e0"/>`;
        svg += `<text x="${ci * colWidth + 10}" y="${y + 20}" font-size="11" font-family="Arial" fill="#333">${String(row[col.key] ?? '').substring(0, 20)}</text>`;
      });
    });

    svg += '</svg>';
    return svg;
  }
}

