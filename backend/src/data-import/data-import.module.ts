import { Module } from '@nestjs/common';
import { DataImportService } from './data-import.service';
import { DataImportController } from './data-import.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [DataImportController],
  providers: [DataImportService],
  exports: [DataImportService],
})
export class DataImportModule {}

