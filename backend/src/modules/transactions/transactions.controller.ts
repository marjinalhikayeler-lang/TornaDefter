import {
  Controller, Get, Post, Put, Delete,
  Body, Param, Query, UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { TransactionsService } from './transactions.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CompanyGuard } from '../../common/guards/company.guard';

@ApiTags('İşlemler')
@Controller('companies/:companyId')
@UseGuards(AuthGuard('jwt'), CompanyGuard)
@ApiBearerAuth('access-token')
export class TransactionsController {
  constructor(private readonly txService: TransactionsService) {}

  @Post('transactions')
  @ApiOperation({ summary: 'Yeni hareket ekle (Borç/Tahsilat/Ödeme)' })
  async create(
    @Param('companyId') companyId: string,
    @CurrentUser('id') userId: string,
    @Body() data: any,
  ) {
    return this.txService.create(companyId, userId, data);
  }

  @Get('transactions')
  @ApiOperation({ summary: 'Tüm hareketler' })
  async findAll(@Param('companyId') companyId: string, @Query() filters: any) {
    return this.txService.findAll(companyId, filters);
  }

  @Get('accounts/:accountId/transactions')
  @ApiOperation({ summary: 'Cari hareketleri (OkLif cari detay)' })
  async findByAccount(
    @Param('companyId') companyId: string,
    @Param('accountId') accountId: string,
    @Query() filters: any,
  ) {
    return this.txService.findByAccount(companyId, accountId, filters);
  }

  @Put('transactions/:transactionId')
  @ApiOperation({ summary: 'Hareket düzenle' })
  async update(
    @Param('companyId') companyId: string,
    @Param('transactionId') txId: string,
    @CurrentUser('id') userId: string,
    @Body() data: any,
  ) {
    return this.txService.update(companyId, txId, userId, data);
  }

  @Delete('transactions/:transactionId')
  @ApiOperation({ summary: 'Hareket sil' })
  async delete(
    @Param('companyId') companyId: string,
    @Param('transactionId') txId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.txService.delete(companyId, txId, userId);
  }
}

