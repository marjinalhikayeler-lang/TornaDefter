import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { CashAccountsService } from './cash-accounts.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CompanyGuard } from '../../common/guards/company.guard';

@ApiTags('Kasa')
@Controller('companies/:companyId/cash-accounts')
@UseGuards(AuthGuard('jwt'), CompanyGuard)
@ApiBearerAuth('access-token')
export class CashAccountsController {
  constructor(private readonly service: CashAccountsService) {}

  @Post()
  @ApiOperation({ summary: 'Yeni kasa oluştur' })
  async create(@Param('companyId') companyId: string, @Body() data: any) {
    return this.service.create(companyId, data);
  }

  @Get()
  @ApiOperation({ summary: 'Kasaları listele' })
  async findAll(@Param('companyId') companyId: string) {
    return this.service.findAll(companyId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Kasa detayı' })
  async findOne(@Param('companyId') companyId: string, @Param('id') id: string) {
    return this.service.findById(companyId, id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Kasa güncelle' })
  async update(@Param('companyId') companyId: string, @Param('id') id: string, @Body() data: any) {
    return this.service.update(companyId, id, data);
  }

  @Get(':id/daily-summary')
  @ApiOperation({ summary: 'Günlük kasa özeti' })
  async dailySummary(@Param('companyId') companyId: string, @Param('id') id: string, @Query('date') date: string) {
    return this.service.dailySummary(companyId, id, date || new Date().toISOString().split('T')[0]);
  }

  @Post(':id/count')
  @ApiOperation({ summary: 'Kasa sayımı' })
  async cashCount(
    @Param('companyId') companyId: string,
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() data: { counted_amount: number },
  ) {
    return this.service.cashCount(companyId, id, userId, data.counted_amount);
  }
}
