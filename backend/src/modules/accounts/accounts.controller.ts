import {
  Controller, Get, Post, Put, Delete,
  Body, Param, Query, UseGuards, Headers,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { AccountsService } from './accounts.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CompanyGuard } from '../../common/guards/company.guard';

@ApiTags('Cari Hesaplar')
@Controller('companies/:companyId/accounts')
@UseGuards(AuthGuard('jwt'), CompanyGuard)
@ApiBearerAuth('access-token')
export class AccountsController {
  constructor(private readonly accountsService: AccountsService) {}

  @Post()
  @ApiOperation({ summary: 'Yeni cari oluştur' })
  async create(@Param('companyId') companyId: string, @Body() data: any) {
    return this.accountsService.create(companyId, data);
  }

  @Get()
  @ApiOperation({ summary: 'Cari listesi' })
  async findAll(@Param('companyId') companyId: string, @Query() filters: any) {
    return this.accountsService.findAll(companyId, filters);
  }

  @Get(':accountId')
  @ApiOperation({ summary: 'Cari detay' })
  async findOne(
    @Param('companyId') companyId: string,
    @Param('accountId') accountId: string,
  ) {
    return this.accountsService.findById(companyId, accountId);
  }

  @Put(':accountId')
  @ApiOperation({ summary: 'Cari düzenle' })
  async update(
    @Param('companyId') companyId: string,
    @Param('accountId') accountId: string,
    @Body() data: any,
  ) {
    return this.accountsService.update(companyId, accountId, data);
  }

  @Delete(':accountId')
  @ApiOperation({ summary: 'Cari sil/arşivle' })
  async delete(
    @Param('companyId') companyId: string,
    @Param('accountId') accountId: string,
  ) {
    return this.accountsService.delete(companyId, accountId);
  }
}

