import { Controller, Get, Post, Delete, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { TransfersService } from './transfers.service';
import { AuthGuard } from '@nestjs/passport';
import { CompanyGuard } from '../../common/guards/company.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('companies/:companyId/transfers')
@UseGuards(AuthGuard('jwt'), CompanyGuard)
export class TransfersController {
  constructor(private readonly service: TransfersService) {}

  @Post()
  create(@Param('companyId') companyId: string, @CurrentUser() user: any, @Body() body: any) {
    return this.service.create(companyId, user.id, body);
  }

  @Get()
  findAll(@Param('companyId') companyId: string, @Query() filters: any) {
    return this.service.findAll(companyId, filters);
  }

  @Get(':id')
  findOne(@Param('companyId') companyId: string, @Param('id') id: string) {
    return this.service.findOne(companyId, id);
  }

  @Delete(':id')
  remove(@Param('companyId') companyId: string, @Param('id') id: string) {
    return this.service.remove(companyId, id);
  }
}
