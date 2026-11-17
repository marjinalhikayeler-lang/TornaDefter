import { Controller, Get, UseGuards } from '@nestjs/common';
import { SubscriptionsService } from './subscriptions.service';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('subscriptions')
@UseGuards(AuthGuard('jwt'))
export class SubscriptionsController {
  constructor(private readonly service: SubscriptionsService) {}

  @Get('active')
  getActivePlan(@CurrentUser() user: any) {
    return this.service.getActivePlan(user.id);
  }

  @Get('plan')
  getPlanInfo() {
    return this.service.getPlanInfo();
  }
}
