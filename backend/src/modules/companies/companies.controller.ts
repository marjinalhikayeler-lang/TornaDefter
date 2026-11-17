import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { CompaniesService } from './companies.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Şirketler')
@Controller('companies')
@UseGuards(AuthGuard('jwt'))
@ApiBearerAuth('access-token')
export class CompaniesController {
  constructor(private readonly companiesService: CompaniesService) {}

  @Post()
  @ApiOperation({ summary: 'Yeni firma oluştur' })
  async create(@CurrentUser('id') userId: string, @Body() data: any) {
    return this.companiesService.create(userId, data);
  }

  @Get()
  @ApiOperation({ summary: 'Firmalarımı listele' })
  async findAll(@CurrentUser('id') userId: string) {
    return this.companiesService.findAllByUser(userId);
  }

  @Get(':companyId')
  @ApiOperation({ summary: 'Firma detayı' })
  async findOne(@Param('companyId') companyId: string) {
    return this.companiesService.findById(companyId);
  }

  @Put(':companyId')
  @ApiOperation({ summary: 'Firma güncelle' })
  async update(@Param('companyId') companyId: string, @Body() data: any) {
    return this.companiesService.update(companyId, data);
  }

  @Post(':companyId/invite')
  @ApiOperation({ summary: 'Kullanıcı davet et' })
  async invite(
    @Param('companyId') companyId: string,
    @CurrentUser('id') userId: string,
    @Body() data: { email: string; role: string },
  ) {
    return this.companiesService.inviteUser(companyId, userId, data.email, data.role as any);
  }

  @Post('invitations/:token/accept')
  @ApiOperation({ summary: 'Daveti kabul et' })
  async acceptInvitation(@Param('token') token: string, @CurrentUser('id') userId: string) {
    return this.companiesService.acceptInvitation(token, userId);
  }

  @Post(':companyId/transfer')
  @ApiOperation({ summary: 'Firma devri' })
  async transferOwnership(
    @Param('companyId') companyId: string,
    @CurrentUser('id') currentOwnerId: string,
    @Body() data: { new_owner_id: string },
  ) {
    return this.companiesService.transferOwnership(companyId, currentOwnerId, data.new_owner_id);
  }
}

