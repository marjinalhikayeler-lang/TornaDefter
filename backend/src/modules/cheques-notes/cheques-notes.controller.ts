import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { ChequesNotesService } from './cheques-notes.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CompanyGuard } from '../../common/guards/company.guard';

@ApiTags('Çek/Senet')
@Controller('companies/:companyId/cheques-notes')
@UseGuards(AuthGuard('jwt'), CompanyGuard)
@ApiBearerAuth('access-token')
export class ChequesNotesController {
  constructor(private readonly service: ChequesNotesService) {}

  @Post()
  @ApiOperation({ summary: 'Yeni çek/senet ekle' })
  async create(@Param('companyId') companyId: string, @Body() data: any) {
    return this.service.create(companyId, data);
  }

  @Get()
  @ApiOperation({ summary: 'Çek/senet listesi' })
  async findAll(@Param('companyId') companyId: string, @Query() filters: any) {
    return this.service.findAll(companyId, filters);
  }

  @Post(':id/status')
  @ApiOperation({ summary: 'Durum değiştir' })
  async changeStatus(
    @Param('companyId') companyId: string,
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() data: { status: string; bank_account_id?: string },
  ) {
    return this.service.changeStatus(companyId, id, userId, data.status as any, data.bank_account_id);
  }

  @Post(':id/endorse')
  @ApiOperation({ summary: 'Çek ciro et' })
  async endorse(
    @Param('companyId') companyId: string,
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() data: { target_account_id: string },
  ) {
    return this.service.endorse(companyId, id, userId, data.target_account_id);
  }
}
