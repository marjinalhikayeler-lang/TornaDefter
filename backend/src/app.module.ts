/**
 * TornaDefter - Ana Uygulama Modülü
 *
 * Tüm özellik modüllerini bir araya getirir.
 * Her modül bağımsız olarak geliştirilebilir ve test edilebilir.
 */

import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

// Çekirdek modüller
import { PrismaModule } from './prisma/prisma.module';

// Özellik modülleri
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { CompaniesModule } from './modules/companies/companies.module';
import { AccountsModule } from './modules/accounts/accounts.module';
import { TransactionsModule } from './modules/transactions/transactions.module';
import { CashAccountsModule } from './modules/cash-accounts/cash-accounts.module';
import { BankAccountsModule } from './modules/bank-accounts/bank-accounts.module';
import { TransfersModule } from './modules/transfers/transfers.module';
import { CategoriesModule } from './modules/categories/categories.module';
import { ChequesNotesModule } from './modules/cheques-notes/cheques-notes.module';
import { IncomeExpensesModule } from './modules/income-expenses/income-expenses.module';
import { ReportsModule } from './modules/reports/reports.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { BackupsModule } from './modules/backups/backups.module';
import { SubscriptionsModule } from './modules/subscriptions/subscriptions.module';
import { SupportModule } from './modules/support/support.module';
import { AdminModule } from './modules/admin/admin.module';
import { InstallmentsModule } from './installments/installments.module';
import { DataImportModule } from './data-import/data-import.module';

@Module({
  imports: [
    // ============================================
    // Ortam değişkenleri yapılandırması
    // ============================================
    ConfigModule.forRoot({
      isGlobal: true, // Tüm modüllerde erişilebilir
      envFilePath: ['.env.local', '.env'],
    }),

    // ============================================
    // Çekirdek modüller
    // ============================================
    PrismaModule,

    // ============================================
    // Özellik modülleri
    // ============================================
    AuthModule,
    UsersModule,
    CompaniesModule,
    AccountsModule,
    TransactionsModule,
    CashAccountsModule,
    BankAccountsModule,
    TransfersModule,
    CategoriesModule,
    ChequesNotesModule,
    IncomeExpensesModule,
    ReportsModule,
    NotificationsModule,
    BackupsModule,
    SubscriptionsModule,
    SupportModule,
    AdminModule,
    InstallmentsModule,
    DataImportModule,
  ],
})
export class AppModule {}
