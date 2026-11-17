/**
 * JWT Stratejisi - Passport
 * İsteklerde JWT token'ı doğrular ve kullanıcı bilgisini request'e ekler.
 */
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET'),
    });
  }

  async validate(payload: { sub: string; email: string }) {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        email: true,
        phone: true,
        first_name: true,
        last_name: true,
        is_active: true,
        email_verified: true,
      },
    });

    if (!user || !user.is_active) {
      throw new UnauthorizedException('Geçersiz veya süresi dolmuş oturum.');
    }

    return user;
  }
}

