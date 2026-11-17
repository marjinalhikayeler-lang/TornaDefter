import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { BankAccountsService } from './bank-accounts.service';
import { AuthGuard } from '@nestjs/passport';
import { CompanyGuard } from '../../common/guards/company.guard';

@Controller('companies/:companyId/bank-accounts')
@UseGuards(AuthGuard('jwt'), CompanyGuard)
export class BankAccountsController {
  constructor(private readonly service: BankAccountsService) {}

  @Post()
  create(@Param('companyId') companyId: string, @Body() body: any) {
    return this.service.create(companyId, body);
  }

  @Get()
  findAll(@Param('companyId') companyId: string, @Query('includeInactive') includeInactive?: string) {
    return this.service.findAll(companyId, includeInactive === 'true');
  }

  @Get('summary')
  getSummary(@Param('companyId') companyId: string) {
    return this.service.getSummary(companyId);
  }

  @Get(':id')
  findOne(@Param('companyId') companyId: string, @Param('id') id: string) {
    return this.service.findOne(companyId, id);
  }

  @Get(':id/transactions')
  getTransactions(
    @Param('companyId') companyId: string,
    @Param('id') id: string,
    @Query() filters: any,
  ) {
    return this.service.getTransactions(companyId, id, filters);
  }

  @Put(':id')
  update(@Param('companyId') companyId: string, @Param('id') id: string, @Body() body: any) {
    return this.service.update(companyId, id, body);
  }

  @Delete(':id')
  remove(@Param('companyId') companyId: string, @Param('id') id: string) {
    return this.service.remove(companyId, id);
  }
}
