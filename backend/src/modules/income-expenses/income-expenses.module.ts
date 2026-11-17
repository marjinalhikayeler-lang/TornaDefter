import { Module } from '@nestjs/common';
import { IncomeExpensesService } from './income-expenses.service';
import { IncomeExpensesController } from './income-expenses.controller';

@Module({
  controllers: [IncomeExpensesController],
  providers: [IncomeExpensesService],
  exports: [IncomeExpensesService],
})
export class IncomeExpensesModule {}
