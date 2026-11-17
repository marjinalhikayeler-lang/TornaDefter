import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('Sistem')
@Controller()
export class AppController {
  @Get('health')
  @ApiOperation({ summary: 'Sistem sağlık kontrolü' })
  health() {
    return {
      status: 'ok',
      service: 'TornaDefter API',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    };
  }

  @Get()
  @ApiOperation({ summary: 'Kök endpoint' })
  root() {
    return {
      name: 'TornaDefter API',
      status: 'running',
      version: '1.0.0',
    };
  }
}

