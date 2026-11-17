import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { ReportsService } from './reports.service';
import { CompanyGuard } from '../../common/guards/company.guard';

@ApiTags('Raporlar')
@Controller('companies/:companyId/reports')
@UseGuards(AuthGuard('jwt'), CompanyGuard)
@ApiBearerAuth('access-token')
export class ReportsController {
  constructor(private readonly service: ReportsService) {}

  @Get('account-balance')
  @ApiOperation({ summary: 'Cari bakiye raporu' })
  async accountBalance(@Param('companyId') cid: string, @Query() f: any) {
    return this.service.accountBalanceReport(cid, f);
  }

  @Get('account-statement/:accountId')
  @ApiOperation({ summary: 'Cari ekstre' })
  async statement(@Param('companyId') cid: string, @Param('accountId') aid: string, @Query() f: any) {
    return this.service.accountStatement(cid, aid, f.start_date, f.end_date);
  }

  @Get('debtors')
  @ApiOperation({ summary: 'Borçlular listesi' })
  async debtors(@Param('companyId') cid: string) {
    return this.service.debtorsReport(cid);
  }

  @Get('aging')
  @ApiOperation({ summary: 'Yaşlandırma raporu' })
  async aging(@Param('companyId') cid: string) {
    return this.service.agingReport(cid);
  }

  @Get('cash-bank')
  @ApiOperation({ summary: 'Kasa/Banka raporu' })
  async cashBank(@Param('companyId') cid: string) {
    return this.service.cashBankReport(cid);
  }

  @Get('income-expense')
  @ApiOperation({ summary: 'Gelir-Gider raporu' })
  async incomeExpense(@Param('companyId') cid: string, @Query() f: any) {
    return this.service.incomeExpenseReport(cid, f.start_date, f.end_date);
  }

  @Get('profit-loss')
  @ApiOperation({ summary: 'Kâr/Zarar özeti' })
  async profitLoss(@Param('companyId') cid: string, @Query() f: any) {
    return this.service.profitLossReport(cid, f.start_date, f.end_date);
  }
}
