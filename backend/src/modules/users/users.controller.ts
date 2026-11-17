import { Controller, Get, Put, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { UsersService } from './users.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Kullanıcılar')
@Controller('users')
@UseGuards(AuthGuard('jwt'))
@ApiBearerAuth('access-token')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Profil bilgilerini getir' })
  async getProfile(@CurrentUser('id') userId: string) {
    return this.usersService.findById(userId);
  }

  @Put('me')
  @ApiOperation({ summary: 'Profil güncelle' })
  async updateProfile(@CurrentUser('id') userId: string, @Body() data: any) {
    return this.usersService.updateProfile(userId, data);
  }

  @Post('me/delete-request')
  @ApiOperation({ summary: 'Hesap silme talebi (KVKK)' })
  async requestDeletion(@CurrentUser('id') userId: string) {
    return this.usersService.requestDeletion(userId);
  }

  @Post('me/cancel-deletion')
  @ApiOperation({ summary: 'Hesap silme talebini iptal et' })
  async cancelDeletion(@CurrentUser('id') userId: string) {
    return this.usersService.cancelDeletion(userId);
  }
}

