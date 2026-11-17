import { Module } from '@nestjs/common';
import { ChequesNotesService } from './cheques-notes.service';
import { ChequesNotesController } from './cheques-notes.controller';

@Module({
  controllers: [ChequesNotesController],
  providers: [ChequesNotesService],
  exports: [ChequesNotesService],
})
export class ChequesNotesModule {}
