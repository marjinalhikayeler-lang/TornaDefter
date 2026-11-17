import { Controller, Get, Post, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { BackupsService } from './backups.service';
import { AuthGuard } from '@nestjs/passport';
import { CompanyGuard } from '../../common/guards/company.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('companies/:companyId/backups')
@UseGuards(AuthGuard('jwt'), CompanyGuard)
export class BackupsController {
  constructor(private readonly service: BackupsService) {}

  @Post()
  create(@Param('companyId') companyId: string, @CurrentUser() user: any) {
    return this.service.create(companyId, user.id);
  }

  @Get()
  findAll(@Param('companyId') companyId: string, @Query() filters: any) {
    return this.service.findAll(companyId, filters);
  }

  @Get(':id')
  findOne(@Param('companyId') companyId: string, @Param('id') id: string) {
    return this.service.findOne(companyId, id);
  }

  @Post(':id/restore')
  restore(@Param('companyId') companyId: string, @Param('id') id: string) {
    return this.service.restore(companyId, id);
  }

  @Delete(':id')
  remove(@Param('companyId') companyId: string, @Param('id') id: string) {
    return this.service.remove(companyId, id);
  }

  @Get('export/data')
  exportData(@Param('companyId') companyId: string, @Query('format') format?: string) {
    return this.service.exportData(companyId, (format as any) || 'json');
  }
}
