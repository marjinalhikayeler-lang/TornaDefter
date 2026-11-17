import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { IncomeExpensesService } from './income-expenses.service';
import { AuthGuard } from '@nestjs/passport';
import { CompanyGuard } from '../../common/guards/company.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('companies/:companyId/income-expenses')
@UseGuards(AuthGuard('jwt'), CompanyGuard)
export class IncomeExpensesController {
  constructor(private readonly service: IncomeExpensesService) {}

  @Post()
  create(@Param('companyId') companyId: string, @CurrentUser() user: any, @Body() body: any) {
    return this.service.create(companyId, user.id, body);
  }

  @Get()
  findAll(@Param('companyId') companyId: string, @Query() filters: any) {
    return this.service.findAll(companyId, filters);
  }

  @Get('summary')
  getSummary(
    @Param('companyId') companyId: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.service.getSummary(companyId, startDate, endDate);
  }

  @Get(':id')
  findOne(@Param('companyId') companyId: string, @Param('id') id: string) {
    return this.service.findOne(companyId, id);
  }

  @Put(':id')
  update(@Param('companyId') companyId: string, @Param('id') id: string, @CurrentUser() user: any, @Body() body: any) {
    return this.service.update(companyId, id, user.id, body);
  }

  @Delete(':id')
  remove(@Param('companyId') companyId: string, @Param('id') id: string) {
    return this.service.remove(companyId, id);
  }
}
