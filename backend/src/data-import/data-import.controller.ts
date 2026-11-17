import {
  Controller, Get, Post, Param, Res, UploadedFile, UseInterceptors, UseGuards, Query,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Response } from 'express';
import { DataImportService } from './data-import.service';
import { AuthGuard } from '@nestjs/passport';
import { CompanyGuard } from '../common/guards/company.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('companies/:companyId/data-import')
@UseGuards(AuthGuard('jwt'), CompanyGuard)
export class DataImportController {
  constructor(private svc: DataImportService) {}

  @Post('accounts')
  @UseInterceptors(FileInterceptor('file'))
  importAccounts(
    @Param('companyId') companyId: string,
    @CurrentUser('id') userId: string,
    @UploadedFile() file: any,
    @Query('sourceApp') sourceApp?: string,
  ) {
    return this.svc.importAccounts(companyId, userId, file.buffer, file.originalname, sourceApp);
  }

  @Get('history')
  listImports(@Param('companyId') companyId: string) {
    return this.svc.listImports(companyId);
  }

  @Get('history/:importId')
  getImport(@Param('companyId') companyId: string, @Param('importId') importId: string) {
    return this.svc.getImport(companyId, importId);
  }

  @Get('template')
  async downloadTemplate(@Res() res: Response) {
    const buffer = await this.svc.getTemplate();
    res.set({
      'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'Content-Disposition': 'attachment; filename=cari-hesap-sablonu.xlsx',
    });
    res.send(buffer);
  }
}

