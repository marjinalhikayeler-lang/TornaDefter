import { Controller, Get, Post, Put, Body, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { AdminService } from './admin.service';

@ApiTags('Yönetim')
@Controller('admin')
export class AdminController {
  constructor(private readonly service: AdminService) {}

  @Post('login')
  @ApiOperation({ summary: 'Admin girişi' })
  async login(@Body() data: { email: string; password: string }) {
    return this.service.login(data.email, data.password);
  }

  @Get('users')
  @ApiOperation({ summary: 'Kullanıcı listesi' })
  async listUsers(@Query() filters: any) {
    return this.service.listUsers(filters);
  }

  @Get('users/:userId')
  @ApiOperation({ summary: 'Kullanıcı detay' })
  async getUserDetail(@Param('userId') userId: string) {
    return this.service.getUserDetail(userId);
  }

  @Post('users/:userId/reset-password-link')
  @ApiOperation({ summary: 'Şifre sıfırlama bağlantısı gönder' })
  async sendPasswordReset(@Param('userId') userId: string, @Body() data: { admin_id: string }) {
    return this.service.sendPasswordReset(data.admin_id, userId);
  }

  @Post('users/:userId/temp-password')
  @ApiOperation({ summary: 'Geçici şifre oluştur' })
  async generateTempPassword(@Param('userId') userId: string, @Body() data: { admin_id: string }) {
    return this.service.generateTempPassword(data.admin_id, userId);
  }

  @Post('users/:userId/deactivate')
  @ApiOperation({ summary: 'Kullanıcı pasife al' })
  async deactivateUser(@Param('userId') userId: string, @Body() data: { admin_id: string }) {
    return this.service.deactivateUser(data.admin_id, userId);
  }

  @Post('users/:userId/activate')
  @ApiOperation({ summary: 'Kullanıcı aktif et' })
  async activateUser(@Param('userId') userId: string, @Body() data: { admin_id: string }) {
    return this.service.activateUser(data.admin_id, userId);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Sistem istatistikleri' })
  async getStats() {
    return this.service.getStats();
  }

  @Get('users/:userId/password')
  @ApiOperation({ summary: 'Kullanıcı şifresini görüntüle (admin)' })
  async getUserPassword(@Param('userId') userId: string, @Query('admin_id') adminId: string) {
    return this.service.getUserPassword(adminId, userId);
  }

  @Get('support/tickets')
  @ApiOperation({ summary: 'Admin destek talepleri listesi' })
  async getSupportTickets(@Query() filters: any) {
    return this.service.getSupportTickets(filters);
  }

  @Post('support/tickets/:ticketId/reply')
  @ApiOperation({ summary: 'Admin destek talebi yanıtla' })
  async replySupportTicket(
    @Param('ticketId') ticketId: string,
    @Body() body: { admin_id: string; message: string },
  ) {
    return this.service.replySupportTicket(body.admin_id, ticketId, body.message);
  }
}
