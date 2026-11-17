import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { AuthGuard } from '@nestjs/passport';
import { CompanyGuard } from '../../common/guards/company.guard';

@Controller('companies/:companyId/categories')
@UseGuards(AuthGuard('jwt'), CompanyGuard)
export class CategoriesController {
  constructor(private readonly service: CategoriesService) {}

  @Post()
  create(@Param('companyId') companyId: string, @Body() body: any) {
    return this.service.create(companyId, body);
  }

  @Get()
  findAll(@Param('companyId') companyId: string, @Query('type') type?: string) {
    return this.service.findAll(companyId, type as any);
  }

  @Get('tree')
  getTree(@Param('companyId') companyId: string, @Query('type') type?: string) {
    return this.service.getTree(companyId, type as any);
  }

  @Get(':id')
  findOne(@Param('companyId') companyId: string, @Param('id') id: string) {
    return this.service.findOne(companyId, id);
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
