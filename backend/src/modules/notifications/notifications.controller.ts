import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('notifications')
@UseGuards(AuthGuard('jwt'))
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  @Get()
  findAll(@CurrentUser() user: any, @Query() filters: any) {
    return this.service.findAll(user.id, filters);
  }

  @Post(':id/read')
  markAsRead(@CurrentUser() user: any, @Param('id') id: string) {
    return this.service.markAsRead(user.id, id);
  }

  @Post('read-all')
  markAllAsRead(@CurrentUser() user: any, @Query('companyId') companyId?: string) {
    return this.service.markAllAsRead(user.id, companyId);
  }

  @Delete(':id')
  remove(@CurrentUser() user: any, @Param('id') id: string) {
    return this.service.remove(user.id, id);
  }

  @Delete()
  clearAll(@CurrentUser() user: any) {
    return this.service.clearAll(user.id);
  }

  @Get('settings')
  getSettings(@CurrentUser() user: any, @Query('companyId') companyId?: string) {
    return this.service.getSettings(user.id, companyId);
  }

  @Put('settings')
  updateSetting(@CurrentUser() user: any, @Body() body: any) {
    return this.service.updateSetting(user.id, body);
  }
}
