import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { SupportService } from './support.service';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('support')
@UseGuards(AuthGuard('jwt'))
export class SupportController {
  constructor(private readonly service: SupportService) {}

  @Post('tickets')
  createTicket(@CurrentUser() user: any, @Body() body: any) {
    return this.service.createTicket(user.id, body);
  }

  @Get('tickets')
  findAllTickets(@CurrentUser() user: any, @Query() filters: any) {
    return this.service.findAllTickets(user.id, filters);
  }

  @Get('tickets/:id')
  findTicket(@CurrentUser() user: any, @Param('id') id: string) {
    return this.service.findTicket(user.id, id);
  }

  @Post('tickets/:id/messages')
  addMessage(@CurrentUser() user: any, @Param('id') id: string, @Body() body: any) {
    return this.service.addMessage(user.id, id, body.message, body.attachments);
  }

  @Put('tickets/:id/close')
  closeTicket(@CurrentUser() user: any, @Param('id') id: string) {
    return this.service.closeTicket(user.id, id);
  }
}
