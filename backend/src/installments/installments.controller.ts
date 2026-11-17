import {
  Controller, Get, Post, Put, Delete, Param, Body, Query, UseGuards,
} from '@nestjs/common';
import { InstallmentsService } from './installments.service';
import { AuthGuard } from '@nestjs/passport';
import { CompanyGuard } from '../common/guards/company.guard';
import { Frequency, PaymentMethod } from '@prisma/client';

@Controller('companies/:companyId/installments')
@UseGuards(AuthGuard('jwt'), CompanyGuard)
export class InstallmentsController {
  constructor(private svc: InstallmentsService) {}

  @Post('plans')
  createPlan(
    @Param('companyId') companyId: string,
    @Body() body: {
      accountId: string;
      transactionId?: string;
      title: string;
      totalAmount: number;
      installmentCount: number;
      startDate: string;
      frequency?: Frequency;
      notes?: string;
    },
  ) {
    return this.svc.createPlan(companyId, body);
  }

  @Get('plans')
  listPlans(
    @Param('companyId') companyId: string,
    @Query('accountId') accountId?: string,
  ) {
    return this.svc.listPlans(companyId, accountId);
  }

  @Get('plans/:planId')
  getPlan(@Param('companyId') companyId: string, @Param('planId') planId: string) {
    return this.svc.getPlan(companyId, planId);
  }

  @Put('plans/:planId/installments/:installmentId/pay')
  payInstallment(
    @Param('companyId') companyId: string,
    @Param('planId') planId: string,
    @Param('installmentId') installmentId: string,
    @Body() body: { paidAmount?: number; paidDate?: string; paymentMethod?: PaymentMethod; notes?: string },
  ) {
    return this.svc.payInstallment(companyId, planId, installmentId, body);
  }

  @Put('plans/:planId/installments/:installmentId/cancel')
  cancelInstallment(
    @Param('companyId') companyId: string,
    @Param('planId') planId: string,
    @Param('installmentId') installmentId: string,
  ) {
    return this.svc.cancelInstallment(companyId, planId, installmentId);
  }

  @Delete('plans/:planId')
  deletePlan(@Param('companyId') companyId: string, @Param('planId') planId: string) {
    return this.svc.deletePlan(companyId, planId);
  }

  @Get('summary')
  getSummary(@Param('companyId') companyId: string) {
    return this.svc.getSummary(companyId);
  }

  @Post('update-overdue')
  updateOverdue(@Param('companyId') companyId: string) {
    return this.svc.updateOverdueInstallments(companyId);
  }
}

